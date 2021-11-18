import AWSLambdaEvents
import AWSLambdaRuntimeCore
import Core
import NIO
import NIOHTTP1

// MARK: Handler

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol KloyAsyncLambdaHandler: EventLoopLambdaHandler {
    /// The Lambda handling method
    /// Concrete Lambda handlers implement this method to provide the Lambda functionality.
    ///
    /// - parameters:
    ///     - event: Event of type `In` representing the event or request.
    ///     - context: Runtime `Context`.
    ///
    /// - Returns: A Lambda result ot type `Out`.
    func handle(event: In, context: Lambda.Context) async throws -> Out
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension KloyAsyncLambdaHandler {
    func handle(context: Lambda.Context, event: In) -> EventLoopFuture<Out> {
        let promise = context.eventLoop.makePromise(of: Out.self)
        promise.completeWithTask {
            try await self.handle(event: event, context: context)
        }
        return promise.futureResult
    }
}

@available(macOS 12.0.0, *)
public struct APIGatewayHandler: KloyAsyncLambdaHandler {
    public typealias In = APIGateway.Request
    public typealias Out = APIGateway.Response
    private let server: Server

    public init(server: Server) {
        self.server = server
    }

    public func handle(event: APIGateway.Request, context: Lambda.Context) async throws -> APIGateway.Response {
        let kloyRequest: Core.Request
        do {
            kloyRequest = try Core.Request(req: event)
        } catch {
            throw error
        }
        let res = await server.process(request: kloyRequest)

        return APIGateway.Response.from(response: res, in: context)
    }
}

// MARK: Request

extension Core.Request {
    init(req: APIGateway.Request) throws {
        var body: Body
        if req.body != nil {
            body = .init(payload: (req.body?.data(using: .utf8))!)
        } else {
            body = .empty
        }
        var headers: [Header] = []
        req.headers.forEach { key, value in
            headers.append(Header(name: key, value: value))
        }

        self.init(method: Core.HTTPMethod(rawValue: req.httpMethod.rawValue)!, headers: headers, uri: req.path, version: .oneOne, body: body)
    }
}

// MARK: Response

extension APIGateway.Response {
    static func from(response: Core.Response, in context: Lambda.Context) -> APIGateway.Response {
        var headers = [String: String]()
        response.headers.forEach {
            if let current = headers[$0.name] {
                headers[$0.name] = "\(current),\($0.value)"
            } else {
                headers[$0.name] = $0.value
            }
        }

        return .init(
            statusCode: AWSLambdaEvents.HTTPResponseStatus(code: UInt(response.status.code)),
            headers: headers,
            body: String(from: response.body)
        )
    }
}
