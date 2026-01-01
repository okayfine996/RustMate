//
//  main.swift
//  RustMateXPC
//
//  XPC Service entry point
//

import Foundation

// Create the service instance
let service = RustMateXPCService()

// Set up the NSXPCListener for this service
let listener = NSXPCListener.service()
listener.delegate = service

// Start the service (this method does not return)
listener.resume()
