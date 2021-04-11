import ArgumentParser
import Lifecycle
import LifecycleNIOCompat
import NIO

struct Tst51: ParsableCommand {
    @Flag(help: "Run as a client")
    var client = false
    mutating func run() throws {
        let signal = ServiceLifecycle.Signal.INT
        let lifecycle = ServiceLifecycle(configuration: .init(shutdownSignal: [signal]))

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let server = myServer(eventLoopGroup: eventLoopGroup)

        lifecycle.registerShutdown(
            label: "eventLoopGroup",
            .sync(eventLoopGroup.syncShutdownGracefully)
        )
        
        lifecycle.register(
            label: "myServer",
            start: .sync(server.run),
            shutdown: .none
        )

        lifecycle.start { error in
            if let error = error {
                print("ERROR: \(error)")
            }
        }
        
        lifecycle.wait()
    }
}

Tst51.main()
