//
//  PubNubManager.swift
//  RealtimeChat
//
//  Created by Carlos Duclos on 11/13/17.
//  Copyright © 2017 Carlos Duclos. All rights reserved.
//

import Foundation
import PubNub

let publishKey = "pub-c-54284d05-4fd1-4555-8cfc-68522861135c"
let subscribeKey = "sub-c-60fc8d60-c8a8-11e7-a719-aab397dfd338"
let secretKey = "sec-c-ZjdjNzg1YzAtMjU0Yi00NjMwLWI0ZjQtNzY3YzZiOTNkNjhm"

class PubNubManager: NSObject {
    
    lazy var config: PNConfiguration = {
        var myConfig = PNConfiguration(publishKey: publishKey, subscribeKey: subscribeKey)
        myConfig.uuid = randomString
        myConfig.origin = "pubsub.pubnub.com"
        myConfig.authKey = secretKey;
        myConfig.stripMobilePayload = false;
        myConfig.presenceHeartbeatValue = 120;
        myConfig.presenceHeartbeatInterval = 5;
        myConfig.keepTimeTokenOnListChange = true;
        myConfig.catchUpOnSubscriptionRestore = true;
        myConfig.requestMessageCountThreshold = 100;
        return myConfig
    }()
    
    lazy var client: PubNub = {
        var myClient = PubNub.clientWithConfiguration(config)
        myClient.logger.enabled = true
        myClient.logger.writeToFile = true
        myClient.logger.maximumLogFileSize = (10 * 1024 * 1024)
        myClient.logger.maximumNumberOfLogFiles = 10
        return myClient
    }()
    
    var channel: String!
    
    static let instance = PubNubManager()
    
    override init() {
        super.init()
        channel = "Channel-2qf3m3wi7"
        client.addListener(self)
    }
    
    var randomString: String {
        return "\(arc4random_uniform(74))"
    }
    
    func start() {
        client.subscribeToChannels([channel], withPresence: false)
    }
    
    func pusblish(message: String) {
        self.client.publish(message, toChannel: channel, compressed: false, withCompletion: { (status) in
            if !status.isError {
                // Message successfully published to specified channel.
                print("Successfully delivered")
            } else{
                /**
                 Handle message publish error. Check 'category' property to find
                 out possible reason because of which request did fail.
                 Review 'errorData' property (which has PNErrorData data type) of status
                 object to get additional information about issue.
                 
                 Request can be resent using: status.retry()
                 */
                print("Error on sending message :(")
            }
        })
    }
    
}

extension PubNubManager: PNObjectEventListener {
    
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        // Handle new message stored in message.data.message
        if message.data.channel != message.data.subscription {
            
            // Message has been received on channel group stored in message.data.subscription.
        } else {
            
            // Message has been received on channel stored in message.data.channel.
        }
        
        print("Received message: \(message.data.message) on channel \(message.data.channel) " + "at \(message.data.timetoken)")
    }
    
    // Handle subscription status change.
    func client(_ client: PubNub, didReceive status: PNStatus) {
        
        if status.operation == .subscribeOperation {
            
            // Check whether received information about successful subscription or restore.
            if status.category == .PNConnectedCategory || status.category == .PNReconnectedCategory {
                
                let subscribeStatus: PNSubscribeStatus = status as! PNSubscribeStatus
                if subscribeStatus.category == .PNConnectedCategory {
                    
                    // This is expected for a subscribe, this means there is no error or issue whatsoever.
                } else {
                    
                    /**
                     This usually occurs if subscribe temporarily fails but reconnects. This means there was
                     an error but there is no longer any issue.
                     */
                }
            } else if status.category == .PNUnexpectedDisconnectCategory {
                
                /**
                 This is usually an issue with the internet connection, this is an error, handle
                 appropriately retry will be called automatically.
                 */
            } else {
                
                let errorStatus: PNErrorStatus = status as! PNErrorStatus
                if errorStatus.category == .PNAccessDeniedCategory {
                    
                    /**
                     This means that PAM does allow this client to subscribe to this channel and channel group
                     configuration. This is another explicit error.
                     */
                } else {
                    
                    /**
                     More errors can be directly specified by creating explicit cases for other error categories
                     of `PNStatusCategory` such as: `PNDecryptionErrorCategory`,
                     `PNMalformedFilterExpressionCategory`, `PNMalformedResponseCategory`, `PNTimeoutCategory`
                     or `PNNetworkIssuesCategory`
                     */
                }
            }
        } else if status.operation == .unsubscribeOperation {
            
            if status.category == .PNDisconnectedCategory {
                
                /**
                 This is the expected category for an unsubscribe. This means there was no error in
                 unsubscribing from everything.
                 */
            }
        } else if status.operation == .heartbeatOperation {
            
            /**
             Heartbeat operations can in fact have errors, so it is important to check first for an error.
             For more information on how to configure heartbeat notifications through the status
             PNObjectEventListener callback, consult http://www.pubnub.com/docs/ios-objective-c/api-reference-configuration#configuration_basic_usage
             */
            
            if !status.isError { /* Heartbeat operation was successful. */ }
            else { /* There was an error with the heartbeat operation, handle here. */ }
        }
    }
    
}

extension PubNubManager {
    
    func handle(_ status: PNErrorStatus) {
        print("^^^^ Debug: \(status.debugDescription)")
        if status.category == .PNAccessDeniedCategory {
            print("^^^^ handleErrorStatus: PAM Error: for resource Will Auto Retry?: \(status.willAutomaticallyRetry ? "YES" : "NO")")
            handlePAMError(status)
        }
        else if status.category == .PNDecryptionErrorCategory {
            print("Decryption error. Be sure the data is encrypted and/or encrypted with the correct cipher key.")
            print("You can find the raw data returned from the server in the status.data attribute: \(status.associatedObject)")
            if status.operation == .subscribeOperation {
                print("""
                    Decryption failed for message from channel: \((status.associatedObject as? PNMessageData)?.channel)
                    message: \((status.associatedObject as? PNMessageData)?.message)
                    """)
            }
        }
        else if status.category == .PNMalformedFilterExpressionCategory {
            print("Value which has been passed to -setFilterExpression: malformed.")
            print("Please verify specified value with declared filtering expression syntax.")
        }
        else if status.category == .PNMalformedResponseCategory {
            print("We were expecting JSON from the server, but we got HTML, or otherwise not legal JSON.")
            print("This may happen when you connect to a public WiFi Hotspot that requires you to auth via your web browser first,")
            print("or if there is a proxy somewhere returning an HTML access denied error, or if there was an intermittent server issue.")
        }
        else if status.category == .PNRequestURITooLongCategory {
            if status.operation == .subscribeOperation {
                print("Too many channels has been passed to subscribe API.")
            }
            else {
                print("Depending from used API this error may mean what to big message has been publish for publish API,")
                print(" or too many channels has been passed to stream controller at once.")
            }
        }
        else if status.category == .PNTimeoutCategory {
            print("For whatever reason, the request timed out. Temporary connectivity issues, etc.")
        }
        else if status.category == .PNNetworkIssuesCategory {
            print("Request can't be processed because of network issues.")
        }
        else {
            // Aside from checking for PAM, this is a generic catch-all if you just want to handle any error, regardless of reason
            // status.debugDescription will shed light on exactly whats going on
            print("Request failed... if this is an issue that is consistently interrupting the performance of your app,")
            print("email the output of debugDescription to support along with all available log info: \(status.debugDescription)")
        }
        
        if status.operation == .heartbeatOperation {
            print("Heartbeat operation failed.")
        }
    }
    
    func handlePAMError(_ status: PNErrorStatus) {
        // Access Denied via PAM. Access status.data to determine the resource in question that was denied.
        // In addition, you can also change auth key dynamically if needed."
        let pamResourceName: String = status.errorData.channels.first!
        let pamResourceType: String = "channel"
        print("PAM error on \(pamResourceType) \(pamResourceName)")
        // If its a PAM error on subscribe, lets grab the channel name in question, and unsubscribe from it, and re-subscribe to a channel that we're authed to
        if status.operation == .subscribeOperation {
            if (pamResourceType == "channel") {
                print("^^^^ Unsubscribing from \(pamResourceName)")
                reconfig(onPAMError: status)
            }
            else {
                client.unsubscribeFromChannelGroups([pamResourceName], withPresence: true)
                // the case where we're dealing with CGs instead of CHs... follows the same pattern as above
            }
        }
        else if status.operation == .publishOperation {
            print("^^^^ Error publishing with authKey: \(secretKey) to channel \(pamResourceName).")
            print("^^^^ Setting auth to an authKey that will allow for both sub and pub")
            reconfig(onPAMError: status)
        }
        
    }
    
    func reconfig(onPAMError status: PNErrorStatus) {
        // If this is a subscribe PAM error
        if status.operation == .subscribeOperation {
            let subscriberStatus = status as? PNSubscribeStatus
            let currentChannels = subscriberStatus?.subscribedChannels
            let currentChannelGroups = subscriberStatus?.subscribedChannelGroups
            config.authKey = "myAuthKey"
            client.copyWithConfiguration(config, completion: {(_ client: PubNub) -> Void in
                self.client = client
                self.client.subscribeToChannels(currentChannels!, withPresence: false)
                self.client.subscribeToChannels(currentChannelGroups!, withPresence: false)
            })
        }
    }
    
}
