import py4j.GatewayServer;

public class JvmAPI {

  public int addition(int first, int second) {
    return first + second;
  }

  public static void main(String[] args) {
    JvmAPI app = new JvmAPI();
    // app is now the gateway.entry_point
    GatewayServer server = new GatewayServer(app);
    server.start();
  }
}
