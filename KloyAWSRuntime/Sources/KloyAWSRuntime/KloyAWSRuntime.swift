import AWSLambdaRuntime
@available(macOS 12.0.0, *)
public class KloyLambda {
    public static func run( with handler: APIGatewayV2Handler){
        Lambda.run { $0.eventLoop.makeSucceededFuture(handler) }
    }
}
