import AWSLambdaEvents
import AWSLambdaRuntimeCore
import Core
import NIO
import NIOHTTP1

// MARK: Handler

@available(macOS 12.0.0, *)
public struct APIGatewayV2Handler: KloyAsyncLambdaHandler {
    public typealias In = APIGateway.V2.Request
    public typealias Out = APIGateway.V2.Response

    private let server: Server

    public init(server: Server) {
        self.server = server
    }

    public func handle(event: APIGateway.V2.Request, context: Lambda.Context) async throws -> APIGateway.V2.Response {
        let kloyRequest: Core.Request
        do {
            kloyRequest = try Core.Request(req: event)
        } catch {
            throw error
        }

        return APIGateway.V2.Response.from(response: await server.process(request: kloyRequest), in: context)
    }
}

// MARK: Request

extension Core.Request {
    init(req: APIGateway.V2.Request) throws {
        var body: Body
        if req.body != nil {
            body = .init(payload: (req.body?.data(using: .utf8))!)
        } else {
            body = .empty
        }
        var headers: [Header] = []
        req.headers.forEach { key, value in
            headers.append(.init(name: key, value: value))
        }

        if let cookies = req.cookies, cookies.count > 0 {
            headers.append(.init(name: "Cookie", value: cookies.joined(separator: "; ")))
        }

        var url: String = req.rawPath
        if req.rawQueryString.count > 0 {
            url += "?\(req.rawQueryString)"
        }
        let method = req.context.http.method.rawValue.lowercased()

        self.init(method: Core.HTTPMethod(rawValue: method)!, headers: headers, uri: url, version: .oneOne, body: body)
    }
}

// MARK: Helpers

func capitalizingFirstLetter(_ s: String) -> String {
    let first = s.prefix(1).capitalized
    let rest = s.dropFirst()
    return first + rest
}

// MARK: Response

extension APIGateway.V2.Response {
    static func from(response: Core.Response, in context: Lambda.Context) -> APIGateway.V2.Response {
        var headers = [String: String]()
        response.headers.forEach {
            if let current = headers[$0.name] {
                headers[$0.name] = "\(current),\($0.value)"
            } else {
                headers[$0.name] = $0.value
            }
        }

        return
            .init(
                statusCode: AWSLambdaEvents.HTTPResponseStatus(code: UInt(response.status.code)),
                headers: headers,
                body: String(from: response.body))
    }
}
