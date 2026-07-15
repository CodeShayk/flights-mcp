"""Server initialization for find-flights MCP."""

import logging
import os
from mcp.server.transport_security import TransportSecuritySettings
from .services.search import mcp

# Set up logging
logger = logging.getLogger(__name__)

def main():
    """Entry point for the find-flights-mcp application.

    Defaults to stdio (unchanged behavior for Claude Desktop / Smithery, which
    spawn this as a local subprocess). Set MCP_TRANSPORT=streamable-http to run
    as a network service instead (e.g. deployed on Railway) - stdio never opens
    a port, it just blocks reading from stdin, which has nothing for a host to
    route traffic to. PORT follows the standard PaaS convention; default 8080.
    """
    logger.info("Starting Find Flights MCP server")
    transport = os.environ.get("MCP_TRANSPORT", "stdio")
    if transport != "stdio":
        mcp.settings.host = os.environ.get("HOST", "0.0.0.0")
        mcp.settings.port = int(os.environ.get("PORT", 8080))
        # The SDK's default DNS-rebinding protection only allows localhost Host headers,
        # which rejects every request arriving through a public host like *.railway.app.
        # That protection matters for locally-hosted servers reachable from a browser;
        # it doesn't apply here, since this is only ever called server-to-server.
        mcp.settings.transport_security = TransportSecuritySettings(
            enable_dns_rebinding_protection=False
        )
    try:
        mcp.run(transport=transport)
    except Exception as e:
        logger.error(f"Server error occurred: {str(e)}", exc_info=True)
        raise

if __name__ == "__main__":
    main()