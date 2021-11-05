import AWSLambdaRuntime

public class KloyLambda {
    public static func Run( with handler: APIGatewayV2Handler){
        Lambda.run { $0.eventLoop.makeSucceededFuture(handler) }
    }
}
