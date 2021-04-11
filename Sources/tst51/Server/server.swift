import NIO
import Logging
let line = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"

private final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
//    public typealias InboundIn = AddressedEnvelope<ByteBuffer>
//    public typealias OutboundOut = AddressedEnvelope<ByteBuffer>
    
    let logger = Logger(label: "myServer EchoHandler")
    private var numBytes = 0

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if self.numBytes == 0 {
            logger.info("T3")
        }

        let byteBuffer = self.unwrapInboundIn(data)
        
        self.numBytes += byteBuffer.readableBytes
    }

    public func channelReadComplete(context: ChannelHandlerContext) {

        let buffer = context.channel.allocator.buffer(string: line)

        if self.numBytes >= 10_000_000 * 40 {
            logger.info("T4")
            context.write(self.wrapOutboundOut(buffer), promise: nil)
//            context.close(promise: nil)
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
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 16)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
//                channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                    channel.pipeline.addHandler(EchoHandler())
//                }
            }

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 32)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
//        defer {
//            try! eventLoopGroup.syncShutdownGracefully()
//        }

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
