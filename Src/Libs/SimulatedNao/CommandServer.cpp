/**
 * @file SimulatedNao/CommandServer.cpp
 * 
 * Implementation of TCP command server.
 */

#include "CommandServer.h"
#include "ConsoleRoboCupCtrl.h"

#include <iostream>
#include <cstring>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

CommandServer::CommandServer(ConsoleRoboCupCtrl* ctrl, int port)
  : ctrl(ctrl), port(port)
{
}

CommandServer::~CommandServer()
{
  stop();
}

void CommandServer::start()
{
  if (running)
    return;
    
  running = true;
  serverThread = std::thread(&CommandServer::serverLoop, this);
  
  ctrl->printLn("CommandServer: Started on port " + std::to_string(port));
}

void CommandServer::stop()
{
  if (!running)
    return;
    
  running = false;
  
  // Close server socket to unblock accept()
  if (serverSocket >= 0)
  {
    close(serverSocket);
    serverSocket = -1;
  }
  
  if (serverThread.joinable())
    serverThread.join();
}

void CommandServer::serverLoop()
{
  // Create socket
  serverSocket = socket(AF_INET, SOCK_STREAM, 0);
  if (serverSocket < 0)
  {
    std::cerr << "CommandServer: Failed to create socket" << std::endl;
    running = false;
    return;
  }
  
  // Allow reuse of address
  int opt = 1;
  setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
  
  // Bind
  sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(port);
  
  if (bind(serverSocket, (sockaddr*)&addr, sizeof(addr)) < 0)
  {
    std::cerr << "CommandServer: Failed to bind to port " << port << std::endl;
    close(serverSocket);
    serverSocket = -1;
    running = false;
    return;
  }
  
  // Listen
  if (listen(serverSocket, 5) < 0)
  {
    std::cerr << "CommandServer: Failed to listen" << std::endl;
    close(serverSocket);
    serverSocket = -1;
    running = false;
    return;
  }
  
  std::cout << "CommandServer: Listening on port " << port << std::endl;
  
  while (running)
  {
    sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);
    
    int clientSocket = accept(serverSocket, (sockaddr*)&clientAddr, &clientLen);
    if (clientSocket < 0)
    {
      if (running)
        std::cerr << "CommandServer: Accept failed" << std::endl;
      continue;
    }
    
    handleClient(clientSocket);
    close(clientSocket);
  }
}

void CommandServer::handleClient(int clientSocket)
{
  char buffer[4096];
  std::string accumulated;
  
  while (running)
  {
    ssize_t bytesRead = recv(clientSocket, buffer, sizeof(buffer) - 1, 0);
    if (bytesRead <= 0)
      break;
      
    buffer[bytesRead] = '\0';
    accumulated += buffer;
    
    // Process complete lines
    size_t pos;
    while ((pos = accumulated.find('\n')) != std::string::npos)
    {
      std::string command = accumulated.substr(0, pos);
      accumulated = accumulated.substr(pos + 1);
      
      // Remove \r if present
      if (!command.empty() && command.back() == '\r')
        command.pop_back();
      
      if (!command.empty())
      {
        std::lock_guard<std::mutex> lock(commandMutex);
        commandQueue.push(command);
      }
    }
    
    // Send acknowledgment
    const char* ack = "OK\n";
    send(clientSocket, ack, strlen(ack), 0);
  }
}

void CommandServer::processCommands()
{
  std::lock_guard<std::mutex> lock(commandMutex);
  
  while (!commandQueue.empty())
  {
    std::string command = commandQueue.front();
    commandQueue.pop();
    
    ctrl->printLn("> " + command);
    ctrl->executeConsoleCommand(command);
  }
}
