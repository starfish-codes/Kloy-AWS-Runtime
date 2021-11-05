import Core
import KloyAwsLambdaRuntime
import AWSLambdaRuntime

func simpleService(status: Status = .ok, body: String) -> (Request) -> Response {
    { request in
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}

KloyLambda.Run(with: APIGatewayV2Handler(server: Server(
        from: routed(route(.Get, "cats") ~> simpleService(body: "All 🐈"))
    ))
)

