// Example: Simple ATProto Service
// This demonstrates a minimal but complete ATProto service implementation

use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use clap::Parser;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::{info, instrument};

#[derive(Parser)]
#[command(name = "simple-service")]
#[command(about = "A simple ATProto service example")]
struct Args {
    #[arg(short, long, default_value = "8080")]
    port: u16,
    
    #[arg(long, default_value = "127.0.0.1")]
    host: String,
    
    #[arg(long, default_value = "info")]
    log_level: String,
}

#[derive(Clone)]
struct AppState {
    // In a real service, this would be a database connection
    // For this example, we use an in-memory store
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
    service: String,
}

#[derive(Deserialize)]
struct CreateRecordRequest {
    repo: String,
    collection: String,
    record: serde_json::Value,
}

#[derive(Serialize)]
struct CreateRecordResponse {
    uri: String,
    cid: String,
}

#[derive(Deserialize)]
struct GetRecordQuery {
    repo: String,
    collection: String,
    rkey: String,
}

#[derive(Serialize)]
struct GetRecordResponse {
    uri: String,
    cid: String,
    value: serde_json::Value,
}

#[instrument]
async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        service: "simple-atproto-service".to_string(),
    })
}

#[instrument(skip(state))]
async fn create_record(
    State(_state): State<AppState>,
    Json(request): Json<CreateRecordRequest>,
) -> Result<Json<CreateRecordResponse>, StatusCode> {
    info!("Creating record in {}/{}", request.repo, request.collection);
    
    // In a real service, you would:
    // 1. Validate the DID and authentication
    // 2. Validate the record against the collection's lexicon
    // 3. Store the record in your database
    // 4. Generate a proper CID for the record
    
    // For this example, we just return a mock response
    let rkey = "example123";
    let uri = format!("at://{}/{}/{}", request.repo, request.collection, rkey);
    let cid = "bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua";
    
    Ok(Json(CreateRecordResponse {
        uri,
        cid: cid.to_string(),
    }))
}

#[instrument(skip(state))]
async fn get_record(
    State(_state): State<AppState>,
    Query(params): Query<GetRecordQuery>,
) -> Result<Json<GetRecordResponse>, StatusCode> {
    info!("Getting record {}/{}/{}", params.repo, params.collection, params.rkey);
    
    // In a real service, you would:
    // 1. Validate the parameters
    // 2. Look up the record in your database
    // 3. Return the actual record data
    
    // For this example, we return a mock record
    let uri = format!("at://{}/{}/{}", params.repo, params.collection, params.rkey);
    let cid = "bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua";
    let value = serde_json::json!({
        "text": "Hello ATProto!",
        "createdAt": "2024-01-01T00:00:00Z"
    });
    
    Ok(Json(GetRecordResponse {
        uri,
        cid: cid.to_string(),
        value,
    }))
}

fn create_router(state: AppState) -> Router {
    Router::new()
        // Health check endpoint
        .route("/health", get(health))
        
        // ATProto XRPC endpoints
        .route("/xrpc/com.atproto.repo.createRecord", post(create_record))
        .route("/xrpc/com.atproto.repo.getRecord", get(get_record))
        
        .with_state(state)
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(format!("simple_atproto_service={}", args.log_level))
        .init();
    
    info!("Starting simple ATProto service on {}:{}", args.host, args.port);
    
    // Initialize application state
    let state = AppState {};
    
    // Create the router
    let app = create_router(state);
    
    // Start the server
    let addr = SocketAddr::new(args.host.parse()?, args.port);
    let listener = TcpListener::bind(addr).await?;
    
    info!("Server listening on {}", addr);
    
    axum::serve(listener, app).await?;
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::StatusCode;
    use axum_test::TestServer;
    
    #[tokio::test]
    async fn test_health_endpoint() {
        let state = AppState {};
        let app = create_router(state);
        let server = TestServer::new(app).unwrap();
        
        let response = server.get("/health").await;
        assert_eq!(response.status_code(), StatusCode::OK);
        
        let health: HealthResponse = response.json();
        assert_eq!(health.status, "healthy");
        assert_eq!(health.service, "simple-atproto-service");
    }
    
    #[tokio::test]
    async fn test_create_record() {
        let state = AppState {};
        let app = create_router(state);
        let server = TestServer::new(app).unwrap();
        
        let request = CreateRecordRequest {
            repo: "did:plc:example123".to_string(),
            collection: "app.bsky.feed.post".to_string(),
            record: serde_json::json!({"text": "Hello World!"}),
        };
        
        let response = server
            .post("/xrpc/com.atproto.repo.createRecord")
            .json(&request)
            .await;
            
        assert_eq!(response.status_code(), StatusCode::OK);
        
        let result: CreateRecordResponse = response.json();
        assert!(result.uri.starts_with("at://did:plc:example123/app.bsky.feed.post/"));
    }
    
    #[tokio::test]
    async fn test_get_record() {
        let state = AppState {};
        let app = create_router(state);
        let server = TestServer::new(app).unwrap();
        
        let response = server
            .get("/xrpc/com.atproto.repo.getRecord")
            .add_query_param("repo", "did:plc:example123")
            .add_query_param("collection", "app.bsky.feed.post")
            .add_query_param("rkey", "example123")
            .await;
            
        assert_eq!(response.status_code(), StatusCode::OK);
        
        let result: GetRecordResponse = response.json();
        assert_eq!(result.uri, "at://did:plc:example123/app.bsky.feed.post/example123");
    }
}