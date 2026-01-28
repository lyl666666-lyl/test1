/**
 * @file NetworkLogger.cpp
 * 
 * Implementation of network logger
 * 
 * @author Assistant
 */

#include "NetworkLogger.h"
#include "Platform/BHAssert.h"
#include <cstring>
#include <iostream>

NetworkLogger::NetworkLogger() : sockfd(-1), networkEnabled(false)
{
}

NetworkLogger::~NetworkLogger()
{
  if(localFile.is_open())
    localFile.close();
  
  if(sockfd >= 0)
    close(sockfd);
}

bool NetworkLogger::init(const std::string& serverIP, int serverPort, const std::string& localLogPath)
{
  // Always open local file as fallback
  localFile.open(localLogPath, std::ios::out);
  if(!localFile.is_open())
  {
    std::cerr << "Failed to open local log file: " << localLogPath << std::endl;
    return false;
  }
  
#ifdef TARGET_ROBOT
  // On real robot, try to setup network logging
  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if(sockfd < 0)
  {
    std::cerr << "Failed to create socket for network logging" << std::endl;
    return true; // Still return true because local file is open
  }
  
  memset(&serverAddr, 0, sizeof(serverAddr));
  serverAddr.sin_family = AF_INET;
  serverAddr.sin_port = htons(serverPort);
  
  if(inet_pton(AF_INET, serverIP.c_str(), &serverAddr.sin_addr) <= 0)
  {
    std::cerr << "Invalid server IP address: " << serverIP << std::endl;
    close(sockfd);
    sockfd = -1;
    return true; // Still return true because local file is open
  }
  
  networkEnabled = true;
  std::cout << "Network logging enabled to " << serverIP << ":" << serverPort << std::endl;
#else
  // Suppress unused parameter warnings in non-robot builds
  (void)serverIP;
  (void)serverPort;
#endif
  
  return true;
}

void NetworkLogger::write(const std::string& message)
{
  std::lock_guard<std::mutex> lock(logMutex);
  
  // Always write to local file
  if(localFile.is_open())
  {
    localFile << message;
  }
  
  // Also send to network if enabled
  if(networkEnabled && sockfd >= 0)
  {
    sendToNetwork(message);
  }
}

void NetworkLogger::flush()
{
  std::lock_guard<std::mutex> lock(logMutex);
  
  if(localFile.is_open())
  {
    localFile.flush();
  }
}

void NetworkLogger::sendToNetwork(const std::string& message)
{
  // Send message via UDP
  // Format: [PlayerNumber]|[Timestamp]|[Message]
  ssize_t sent = sendto(sockfd, message.c_str(), message.length(), 0,
                        (struct sockaddr*)&serverAddr, sizeof(serverAddr));
  
  if(sent < 0)
  {
    // Network error, but don't fail - local file still works
    static int errorCount = 0;
    if(errorCount++ < 5) // Only print first 5 errors
    {
      std::cerr << "Failed to send log to network (error " << errorCount << ")" << std::endl;
    }
  }
}
