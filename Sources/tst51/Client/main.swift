import ArgumentParser
import Lifecycle
import LifecycleNIOCompat
import NIO

struct Tst51: ParsableCommand {
    mutating func run() throws {
    let signal = ServiceLifecycle.Signal.INT
    let lifecycle = ServiceLifecycle(configuration: .init(shutdownSignal: [signal]))

        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = myClient(eventLoopGroup: eventLoopGroup)
        lifecycle.registerShutdown(
            label: "eventLoopGroup",
            .sync(eventLoopGroup.syncShutdownGracefully)
        )

        lifecycle.register(
            label: "myClient",
            start: .sync(client.run),
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
