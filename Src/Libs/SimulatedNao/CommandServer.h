/**
 * @file SimulatedNao/CommandServer.h
 * 
 * TCP server for receiving console commands from external applications.
 * This allows GUI applications to control SimRobot remotely.
 * 
 * @author Education Project
 */

#pragma once

#include <string>
#include <thread>
#include <atomic>
#include <mutex>
#include <queue>

class ConsoleRoboCupCtrl;

/**
 * TCP server that listens for console commands.
 * Commands are queued and executed in the main SimRobot thread.
 */
class CommandServer
{
public:
  /**
   * Constructor.
   * @param ctrl The console controller to execute commands.
   * @param port The TCP port to listen on (default: 12345).
   */
  CommandServer(ConsoleRoboCupCtrl* ctrl, int port = 12345);
  
  /**
   * Destructor. Stops the server.
   */
  ~CommandServer();
  
  /**
   * Start the server in a background thread.
   */
  void start();
  
  /**
   * Stop the server.
   */
  void stop();
  
  /**
   * Process any pending commands.
   * Should be called from the main thread in update().
   */
  void processCommands();
  
  /**
   * Check if server is running.
   */
  bool isRunning() const { return running; }

private:
  ConsoleRoboCupCtrl* ctrl;
  int port;
  int serverSocket = -1;
  std::atomic<bool> running{false};
  std::thread serverThread;
  
  std::mutex commandMutex;
  std::queue<std::string> commandQueue;
  
  /**
   * Server thread function.
   */
  void serverLoop();
  
  /**
   * Handle a client connection.
   */
  void handleClient(int clientSocket);
};
