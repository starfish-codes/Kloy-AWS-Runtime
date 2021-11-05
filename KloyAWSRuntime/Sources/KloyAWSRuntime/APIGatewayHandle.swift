import AWSLambdaEvents
import AWSLambdaRuntimeCore
import NIO
import NIOHTTP1
import Core
// MARK:  Handler

public struct APIGatewayHandler: EventLoopLambdaHandler {
    public typealias In = APIGateway.Request
    public typealias Out = APIGateway.Response
    private let server: Server
    
    public init(server: Server) {
        self.server = server
    }

    public func handle(context: Lambda.Context, event: In)
    -> EventLoopFuture<Out>
    {
        let kloyRequest: Core.Request
        do {
            kloyRequest = try Core.Request(req: event)
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
        
        return APIGateway.Response.from(response: server.process(request: kloyRequest), in: context)
    }
}

// MARK:  Request

extension Core.Request {
    init(req: APIGateway.Request) throws {
        var body: Body
        if (req.body != nil) {
            body = .init(payload: ((req.body?.data(using: .utf8))!))
        }else{
            body = .empty
        }
        var headers: [Header] = []
        req.headers.forEach { key, value in
            headers.append(.init(name: key, value: value))
        }
        
        self.init(method: Core.HTTPMethod(rawValue: req.httpMethod.rawValue)!, headers: headers, uri : req.path, version: .OneOne, body: body)
    }
}
// MARK:  Response
extension APIGateway.Response {
    static func from(response: Core.Response, in context: Lambda.Context) -> EventLoopFuture<APIGateway.Response> {
        var headers = [String: String]()
        response.headers.forEach {
            if let current = headers[$0.name] {
                headers[$0.name] = "\(current),\($0.value)"
            } else {
                headers[$0.name] = $0.value
            }
        }
        
        if let body = response.body {
            return context.eventLoop.makeSucceededFuture(.init(
                statusCode: AWSLambdaEvents.HTTPResponseStatus(code: UInt(response.status.code)),
                headers: headers,
                body: String(from: body)            ))
        } else {
            
            return context.eventLoop.makeSucceededFuture(.init(
                statusCode: AWSLambdaEvents.HTTPResponseStatus(code: UInt(response.status.code)),
                headers: headers
            ))
        }
    }
}
