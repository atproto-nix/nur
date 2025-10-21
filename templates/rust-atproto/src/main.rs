use anyhow::Result;
use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use clap::Parser;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::{info, instrument};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Parser, Debug)]
#[command(name = "my-atproto-service")]
#[command(about = "My ATProto Rust service")]
struct Args {
    /// Port to listen on
    #[arg(short, long, default_value = "8080")]
    port: u16,

    /// Host to bind to
    #[arg(long, default_value = "127.0.0.1")]
    host: String,

    /// Log level
    #[arg(long, default_value = "info")]
    log_level: String,
}

#[derive(Clone)]
struct AppState {
    // Add your application state here
    // e.g., database connection, configuration, etc.
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
}

#[derive(Deserialize)]
struct AtprotoRequest {
    // Define your ATProto request structure
    did: String,
    collection: String,
}

#[derive(Serialize)]
struct AtprotoResponse {
    // Define your ATProto response structure
    success: bool,
    message: String,
}

#[instrument]
async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}

#[instrument]
async fn handle_atproto_request(
    State(_state): State<AppState>,
    Json(request): Json<AtprotoRequest>,
) -> Result<Json<AtprotoResponse>, StatusCode> {
    info!("Processing ATProto request for DID: {}", request.did);
    
    // TODO: Implement your ATProto logic here
    // This is where you would:
    // 1. Validate the request
    // 2. Process the ATProto operation
    // 3. Update your data store
    // 4. Return the appropriate response
    
    Ok(Json(AtprotoResponse {
        success: true,
        message: format!("Processed request for {}", request.did),
    }))
}

fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/xrpc/com.atproto.repo.createRecord", post(handle_atproto_request))
        // Add more ATProto endpoints as needed
        .with_state(state)
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| format!("my_atproto_service={}", args.log_level).into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    info!("Starting ATProto service on {}:{}", args.host, args.port);

    // Initialize application state
    let state = AppState {
        // Initialize your state here
    };

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
    }

    #[tokio::test]
    async fn test_atproto_endpoint() {
        let state = AppState {};
        let app = create_router(state);
        let server = TestServer::new(app).unwrap();

        let request = AtprotoRequest {
            did: "did:plc:example123".to_string(),
            collection: "app.bsky.feed.post".to_string(),
        };

        let response = server
            .post("/xrpc/com.atproto.repo.createRecord")
            .json(&request)
            .await;
            
        assert_eq!(response.status_code(), StatusCode::OK);
        
        let result: AtprotoResponse = response.json();
        assert!(result.success);
    }
}