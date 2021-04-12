import NIO
import Logging

let line = "1234567890123456789012345678901234567890"
private final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    let logger = Logger(label: "myServer EchoHandler")
    private var numBytes = 0
    let iterations = 1_000
    let outerIterations = 50_000
    var currentIteration = 1
    let lineLength = line.count
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if self.numBytes == 0 {
            logger.info("T3")
        }

        let byteBuffer = self.unwrapInboundIn(data)
        
        self.numBytes += byteBuffer.readableBytes
    }

    public func channelReadComplete(context: ChannelHandlerContext) {

        if self.numBytes >= iterations * currentIteration * lineLength {
            let buffer = context.channel.allocator.buffer(string: line)
            context.write(self.wrapOutboundOut(buffer), promise: nil)
            currentIteration += 1
        }
        if self.numBytes >= iterations * outerIterations * lineLength {
            logger.info("T4")
        }
        context.flush()
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("error: \(error)")
        context.close(promise: nil)
    }
}

struct myServer {
    var eventLoopGroup : EventLoopGroup
    let logger = Logger(label: "myServer")

    func run() throws {
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 16)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                    channel.pipeline.addHandler(EchoHandler())
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator(minimum: 1024, initial: 2048, maximum: 1024*1024))

        // First argument is the program path
        let arguments = CommandLine.arguments
        let arg1 = arguments.dropFirst().first
        let arg2 = arguments.dropFirst(2).first

        let defaultHost = "::1"
        let defaultPort = 9999

        enum BindTo {
            case ip(host: String, port: Int)
            case unixDomainSocket(path: String)
        }

        let bindTarget: BindTo
        switch (arg1, arg1.flatMap(Int.init), arg2.flatMap(Int.init)) {
        case (.some(let h), _ , .some(let p)):
            /* we got two arguments, let's interpret that as host and port */
            bindTarget = .ip(host: h, port: p)
        case (.some(let portString), .none, _):
            /* couldn't parse as number, expecting unix domain socket path */
            bindTarget = .unixDomainSocket(path: portString)
        case (_, .some(let p), _):
            /* only one argument --> port */
            bindTarget = .ip(host: defaultHost, port: p)
        default:
            bindTarget = .ip(host: defaultHost, port: defaultPort)
        }

        let channel = try { () -> Channel in
            switch bindTarget {
            case .ip(let host, let port):
                return try bootstrap.bind(host: host, port: port).wait()
            case .unixDomainSocket(let path):
                return try bootstrap.bind(unixDomainSocketPath: path).wait()
            }
        }()

        logger.info("Server started and listening on \(channel.localAddress!)")

//        try channel.closeFuture.wait()
    }
}
