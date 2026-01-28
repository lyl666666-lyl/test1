/**
 * @file NetworkLogger.h
 * 
 * Network logger that sends log messages to a remote server
 * 
 * @author Assistant
 */

#pragma once

#include <string>
#include <fstream>
#include <mutex>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

class NetworkLogger
{
public:
  NetworkLogger();
  ~NetworkLogger();
  
  /**
   * Initialize the network logger
   * @param serverIP IP address of the log server (development machine)
   * @param serverPort Port of the log server
   * @param localLogPath Local log file path (fallback)
   * @return true if initialization succeeded
   */
  bool init(const std::string& serverIP, int serverPort, const std::string& localLogPath);
  
  /**
   * Write a log message
   * @param message The log message to write
   */
  void write(const std::string& message);
  
  /**
   * Flush the log
   */
  void flush();
  
  /**
   * Check if logger is ready
   */
  bool isOpen() const { return localFile.is_open(); }
  
private:
  std::ofstream localFile;  // Local file as fallback
  std::mutex logMutex;      // Thread safety
  int sockfd;               // UDP socket
  struct sockaddr_in serverAddr;
  bool networkEnabled;
  
  void sendToNetwork(const std::string& message);
};
