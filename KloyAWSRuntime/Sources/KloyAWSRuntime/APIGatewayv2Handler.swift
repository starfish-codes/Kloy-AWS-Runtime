import AWSLambdaEvents
import AWSLambdaRuntimeCore
import NIO
import NIOHTTP1
import Core
import ObjectiveC

// MARK:  Handler

public struct APIGatewayV2Handler: EventLoopLambdaHandler {
    public  typealias In = APIGateway.V2.Request
    public typealias Out = APIGateway.V2.Response
    
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
        
        return APIGateway.V2.Response.from(response: server.process(request: kloyRequest), in: context)
    }
}

// MARK:  Request

extension Core.Request {
    init(req: APIGateway.V2.Request) throws {
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
        
        if let cookies = req.cookies, cookies.count > 0 {
            headers.append(.init(name: "Cookie", value: cookies.joined(separator: "; ")))
        }
        
        var url: String = req.rawPath
        if req.rawQueryString.count > 0 {
            url += "?\(req.rawQueryString)"
        }
        let method = capitalizingFirstLetter(req.context.http.method.rawValue.lowercased())
        
        self.init(method: Core.HTTPMethod(rawValue: method)!, headers: headers, uri: url, version: .OneOne, body: body)
    }
}
// MARK: Helpers
func capitalizingFirstLetter(_ s:String) -> String {
    let first = s.prefix(1).capitalized
    let rest = s.dropFirst()
    return first + rest
}


// MARK:  Response
extension APIGateway.V2.Response {
    static func from(response: Core.Response, in context: Lambda.Context) -> EventLoopFuture<APIGateway.V2.Response> {
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

