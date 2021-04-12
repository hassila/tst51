import NIO
import Logging

let line = "1234567890123456789012345678901234567890"
private final class EchoHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    private var numBytes = 0
    let logger = Logger(label: "myClient EchoHandler")
    let iterations = 1_000
    let outerIterations = 50_000
    let lineLength = line.count

    public func writeChunk(context: ChannelHandlerContext) {
        let buffer = context.channel.allocator.buffer(string: line)
        for _ in 0..<iterations {
            self.numBytes += buffer.readableBytes
            context.write(self.wrapOutboundOut(buffer), promise: nil)
        }
        context.flush()
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        logger.info("Client connected to \(context.remoteAddress!)")
        writeChunk(context: context)
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if self.numBytes < iterations * outerIterations * 40 {
            writeChunk(context: context)
        } else {
            logger.info("Received all data from server back [\(self.numBytes)] bytes, closing channel.")
            context.close(promise: nil)
        }
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("error: \(error)")
        context.close(promise: nil)
    }
}

struct myClient {
    var eventLoopGroup : EventLoopGroup
    let logger = Logger(label: "myClient")

    func run() throws {
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelOption(ChannelOptions.Types.WriteBufferWaterMarkOption(),
                           value: ChannelOptions.Types.WriteBufferWaterMark(low: 32 * 1024, high: 1 * 1024 * 1024)) 
            .channelInitializer { channel in
                channel.pipeline.addHandler(EchoHandler())
            }
        defer {
            try! eventLoopGroup.syncShutdownGracefully()
        }

        // First argument is the program path
        let arguments = CommandLine.arguments
        let arg1 = arguments.dropFirst(2).first
        let arg2 = arguments.dropFirst(3).first

        let defaultHost = "::1"
        let defaultPort: Int = 9999

        enum ConnectTo {
            case ip(host: String, port: Int)
            case unixDomainSocket(path: String)
        }
        let connectTarget: ConnectTo

        switch (arg1, arg1.flatMap(Int.init), arg2.flatMap(Int.init)) {
        default:
            connectTarget = .ip(host: defaultHost, port: defaultPort)
        }

        let channel = try { () -> Channel in
            switch connectTarget {
            case .ip(let host, let port):
                return try bootstrap.connect(host: host, port: port).wait()
            case .unixDomainSocket(let path):
                return try bootstrap.connect(unixDomainSocketPath: path).wait()
            }
        }()

        // Will be closed after we echo-ed back to the server.
        try channel.closeFuture.wait()

        logger.info("Client closed")
    }
}

