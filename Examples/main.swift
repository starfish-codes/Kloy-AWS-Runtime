import AWSLambdaRuntime
import Core
import KloyAWSRuntime

func simpleService(status: Status = .ok, body: String) -> (Request) -> Response {
    { request in
        Response(status: status, headers: [], version: request.version, body: .init(from: body)!)
    }
}

if #available(macOS 12.0.0, *) {
    KloyLambda.run(
        with: APIGatewayV2Handler(
            server: Server(
                from: routed(route(.get, "cats") ~> simpleService(body: "All 🐈"))
            )
        )
    )
} else {
    // Fallback on earlier versions
}

