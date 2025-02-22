/**
 * @author Serhii Mamontov
 * @version 4.15.0
 * @since 4.0.0
 * @copyright © 2010-2020 PubNub, Inc.
 */
#import "PubNub+Publish.h"
#import "PNBasePublishRequest+Private.h"
#import "PNAPICallBuilder+Private.h"
#import "PNRequestParameters.h"
#import "PubNub+CorePrivate.h"
#import "PNStatus+Private.h"
#import "PNConfiguration.h"
#import "PNPublishStatus.h"
#import "PNLogMacro.h"
#import "PNHelpers.h"
#import "PNAES.h"


NS_ASSUME_NONNULL_BEGIN

#pragma mark Private interface declaration

@interface PubNub (PublishProtected)


#pragma mark - Composite message publish

/**
 * @brief Send provided Foundation object to \b PubNub service.
 *
 * @param message Object (\a NSString, \a NSNumber, \a NSArray, \a NSDictionary) which will be
 *     published.
 * @param channel Name of the channel to which message should be published.
 * @param payloads Dictionary with payloads for different vendors (Apple with "apns" key and Google
 *     with "gcm").
 * @param shouldStore Whether message should be stored and available with history API or not.
 * @param ttl How long message should be stored in channel's storage. If \b 0 it will be
 *     stored forever or if \c nil - depends from account configuration.
 * @param compressed Whether message should be compressed before sending or not.
 * @param replicate Whether message should be replicated across the PubNub Real-Time Network and
 *     sent simultaneously to all subscribed clients on a channel.
 * @param metadata \b NSDictionary with values which should be used by \b PubNub service to filter
 *     messages.
 * @param queryParameters List arbitrary query parameters which should be sent along with original
 *     API call.
 * @param block Publish completion block which.
 *
 * @since 4.8.2
 */
- (void)publish:(nullable id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(nullable NSDictionary<NSString *, id> *)payloads
       storeInHistory:(BOOL)shouldStore
                  ttl:(nullable NSNumber *)ttl
           compressed:(BOOL)compressed
      withReplication:(BOOL)replicate
             metadata:(nullable NSDictionary<NSString *, id> *)metadata
      queryParameters:(nullable NSDictionary *)queryParameters
           completion:(nullable PNPublishCompletionBlock)block;


#pragma mark - Signal

/**
 * @brief Send provided Foundation object to \b PubNub service.
 *
 * @discussion Provided object will be serialized into JSON string before pushing to \b PubNub
 * service. If client has been configured with cipher key message will be encrypted as well.
 *
 * @param message Object (\a NSString, \a NSNumber, \a NSArray, \a NSDictionary) which will be
 *     sent with signal.
 * @param channel Name of the channel to which signal should be sent.
 * @param queryParameters List arbitrary query parameters which should be sent along with original
 *     API call.
 * @param block Signal completion block.
 *
 * @since 4.9.0
 */
- (void)signal:(id)message
                channel:(NSString *)channel
    withQueryParameters:(nullable NSDictionary *)queryParameters
             completion:(nullable PNSignalCompletionBlock)block;


#pragma mark - Message helper

/**
 * @brief Helper method which allow to calculate resulting message before it will be sent to
 * \b PubNub network.
 *
 * @note Size calculation use percent-escaped \c message and all added headers to get full size.
 *
 * @param message Message for which size should be calculated.
 * @param channel Name of the channel to which message should be published.
 * @param compressMessage Whether message should be compressed before sending or not.
 * @param shouldStore Whether message should be stored and available with history API or not.
 * @param ttl How long message should be stored in channel's storage. If \b 0 it will be
 *     stored forever or if \c nil - depends from account configuration.
 * @param replicate Whether message should be replicated across the PubNub Real-Time Network and
 *     sent simultaneously to all subscribed clients on a channel.
 * @param metadata \b NSDictionary with values which should be used by \b PubNub service to filter
 *     messages.
 * @param queryParameters List arbitrary query parameters which should be sent along with original
 *     API call.
 * @param block Message size calculation completion block.
 *
 * @since 4.8.2
 */
- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
           compressed:(BOOL)compressMessage
       storeInHistory:(BOOL)shouldStore
                  ttl:(nullable NSNumber *)ttl
      withReplication:(BOOL)replicate
             metadata:(nullable NSDictionary<NSString *, id> *)metadata
      queryParameters:(nullable NSDictionary *)queryParameters
           completion:(PNMessageSizeCalculationCompletionBlock)block;


#pragma mark - Handlers

/**
 * @brief Handle publish builder perform with block call.
 *
 * @note Logic moved into separate method because it shared between two almost identical API calls
 * (regular publish and fire which doesn't store message in storage and won't replicate it).
 *
 * @param flags List of conditional flags which has been generated by builder on user request.
 * @param parameters List of user-provided data which will be consumed by used API endpoint.
 *
 * @since 4.5.4
 */
- (void)handlePublishBuilderExecutionWithFlags:(NSArray<NSString *> *)flags 
                                    parameters:(NSDictionary *)parameters;


#pragma mark - Misc

/**
 * @brief Compose set of parameters which is required to publish message.
 *
 * @param message Object (\a NSString, \a NSNumber, \a NSArray, \a NSDictionary) which will be
 *     published.
 * @param channel Name of the channel to which message should be published.
 * @param compressMessage Whether message should be compressed before sending or not.
 * @param replicate Whether message should be replicated across the PubNub Real-Time Network and
 *     sent simultaneously to all subscribed clients on a channel.
 * @param shouldStore Whether message should be stored and available with history API or not.
 * @param ttl How long message should be stored in channel's storage. If \b 0 it will be
 *     stored forever or if \c nil - depends from account configuration.
 * @param metadata \b NSDictionary with values which should be used by \b PubNub service to filter
 *     messages.
 * @param sequenceNumber Next published message sequence number which should be used.
 * @param queryParameters List arbitrary query parameters which should be sent along with original
 *     API call.
 *
 * @return Configured and ready to use request parameters instance.
 *
 * @since 4.0
 */
- (PNRequestParameters *)requestParametersForMessage:(NSString *)message
                                           toChannel:(NSString *)channel
                                          compressed:(BOOL)compressMessage
                                      storeInHistory:(BOOL)shouldStore
                                                 ttl:(nullable NSNumber *)ttl
                                           replicate:(BOOL)replicate
                                            metadata:(nullable NSString *)metadata
                                      sequenceNumber:(NSUInteger)sequenceNumber
                                     queryParameters:(NSDictionary *)queryParameters;

/**
 * @brief Merge user-specified message with push payloads into single message which will be
 * processed on \b PubNub service.
 *
 * @discussion In case if aside from \c message has been passed \c payloads this method will merge
 * them into format known by \b PubNub service and will cause further push distribution to specified
 * vendors.
 *
 * @param message Message which should be merged with \c payloads.
 * @param payloads \b NSDictionary with payloads for different push notification services
 *     (Apple with "apns" key and Google with "gcm").
 *
 * @return Merged message or original message if there is no data in \c payloads.
 *
 * @since 4.0
 */
- (NSDictionary<NSString *, id> *)mergedMessage:(nullable id)message
                          withMobilePushPayload:(nullable NSDictionary<NSString *, id> *)payloads;

/**
 * @brief Try perform encryption of data which should be pushed to \b PubNub services.
 *
 * @param message Data which \b PNAES should try to encrypt.
 * @param key Cipher key which should be used during encryption.
 * @param randomIV Whether random initialization vector should be used or not.
 * @param error Pointer into which data encryption error will be passed.
 *
 * @return Encrypted Base64-encoded string or original message, if there is no \c key has been
 * passed.
 *
 * @since 4.16.0
 */
- (nullable NSString *)encryptedMessage:(NSString *)message
                          withCipherKey:(NSString *)key
             randomInitializationVector:(BOOL)randomIV
                                  error:(NSError **)error;

#pragma mark -


@end

NS_ASSUME_NONNULL_END


#pragma mark - Interface implementation

@implementation PubNub (Publish)


#pragma mark - API Builder support

- (PNPublishFileMessageAPICallBuilder * (^)(void))publishFileMessage {
    PNPublishFileMessageAPICallBuilder *builder = nil;
    __weak __typeof(self) weakSelf = self;
    
    builder = [PNPublishFileMessageAPICallBuilder builderWithExecutionBlock:^(NSArray<NSString *> *flags,
                                                                              NSDictionary *parameters) {
                                                                       
        NSString *identifier = parameters[NSStringFromSelector(@selector(fileIdentifier))];
        NSString *filename = parameters[NSStringFromSelector(@selector(fileName))];
        NSString *channel = parameters[NSStringFromSelector(@selector(channel))];
        NSNumber *shouldStore = parameters[NSStringFromSelector(@selector(shouldStore))];
        NSNumber *ttl = parameters[NSStringFromSelector(@selector(ttl))];
        
        if (shouldStore && !shouldStore.boolValue) {
            ttl = nil;
        }

        PNPublishFileMessageRequest *request = [PNPublishFileMessageRequest requestWithChannel:channel
                                                                                fileIdentifier:identifier
                                                                                          name:filename];
        request.metadata = parameters[NSStringFromSelector(@selector(metadata))];
        request.message = parameters[NSStringFromSelector(@selector(message))];
        request.arbitraryQueryParameters = parameters[@"queryParam"];
        request.store = (shouldStore ? shouldStore.boolValue : YES);
        request.ttl = ttl.unsignedIntegerValue;
        
        [weakSelf publishFileMessageWithRequest:request completion:parameters[@"block"]];
    }];
    
    return ^PNPublishFileMessageAPICallBuilder * {
        return builder;
    };
}

- (PNPublishAPICallBuilder * (^)(void))publish {
    
    PNPublishAPICallBuilder *builder = nil;
    __weak __typeof(self) weakSelf = self;
    builder = [PNPublishAPICallBuilder builderWithExecutionBlock:^(NSArray<NSString *> *flags, 
                                                                   NSDictionary *parameters) {
                                                                       
        NSString *channel = parameters[NSStringFromSelector(@selector(channel))];
        NSNumber *shouldStore = parameters[NSStringFromSelector(@selector(shouldStore))];
        NSNumber *ttl = parameters[NSStringFromSelector(@selector(ttl))];
        NSNumber *compressed = parameters[NSStringFromSelector(@selector(compress))];
        NSNumber *replicate = parameters[NSStringFromSelector(@selector(replicate))];
        
        if (shouldStore && !shouldStore.boolValue) {
            ttl = nil;
        }

        PNPublishRequest *request = [PNPublishRequest requestWithChannel:channel];
        request.metadata = parameters[NSStringFromSelector(@selector(metadata))];
        request.payloads = parameters[NSStringFromSelector(@selector(payloads))];
        request.message = parameters[NSStringFromSelector(@selector(message))];
        request.arbitraryQueryParameters = parameters[@"queryParam"];
        request.store = (shouldStore ? shouldStore.boolValue : YES);
        request.replicate = (replicate ? replicate.boolValue : YES);
        request.compress = compressed.boolValue;
        request.ttl = ttl.unsignedIntegerValue;
                                     
        [weakSelf publishWithRequest:request completion:parameters[@"block"]];
    }];
    
    return ^PNPublishAPICallBuilder * {
        return builder;
    };
}

- (PNPublishAPICallBuilder * (^)(void))fire {
    
    PNPublishAPICallBuilder *builder = nil;
    __weak __typeof(self) weakSelf = self;
    builder = [PNPublishAPICallBuilder builderWithExecutionBlock:^(NSArray<NSString *> *flags, 
                                                                   NSDictionary *parameters) {
        
        [weakSelf handlePublishBuilderExecutionWithFlags:flags parameters:parameters];
    }];

    [builder setValue:@NO forParameter:NSStringFromSelector(@selector(shouldStore))];
    [builder setValue:@NO forParameter:NSStringFromSelector(@selector(replicate))];
    
    return ^PNPublishAPICallBuilder * {
        return builder;
    };
}

- (PNSignalAPICallBuilder * (^)(void))signal {
    
    PNSignalAPICallBuilder * builder = nil;
    __weak __typeof(self) weakSelf = self;
    builder = [PNSignalAPICallBuilder builderWithExecutionBlock:^(NSArray<NSString *> *flags,
                                                                  NSDictionary *parameters) {
        
        id message = parameters[NSStringFromSelector(@selector(message))];
        NSString *channel = parameters[NSStringFromSelector(@selector(channel))];
        NSDictionary *queryParam = parameters[@"queryParam"];
        id block = parameters[@"block"];
        
        [weakSelf signal:message channel:channel withQueryParameters:queryParam completion:block];
    }];
    
    return ^PNSignalAPICallBuilder * {
        return builder;
    };
}

- (PNPublishSizeAPICallBuilder * (^)(void))size {
    
    PNPublishSizeAPICallBuilder *builder = nil;
    builder = [PNPublishSizeAPICallBuilder builderWithExecutionBlock:^(NSArray<NSString *> *flags,
                                                                       NSDictionary *parameters) {
                                     
        id message = parameters[NSStringFromSelector(@selector(message))];
        NSString *channel = parameters[NSStringFromSelector(@selector(channel))];
        NSNumber *shouldStore = parameters[NSStringFromSelector(@selector(shouldStore))];
        NSNumber *ttl = parameters[NSStringFromSelector(@selector(ttl))];
        NSNumber *compressed = parameters[NSStringFromSelector(@selector(compress))];
        NSNumber *replicate = parameters[NSStringFromSelector(@selector(replicate))];
        NSDictionary *metadata = parameters[NSStringFromSelector(@selector(metadata))];
        NSDictionary *queryParam = parameters[@"queryParam"];
        id block = parameters[@"block"];

        if (shouldStore && !shouldStore.boolValue) {
            ttl = nil;
        }
                                         
        [self sizeOfMessage:message
                  toChannel:channel
                 compressed:compressed.boolValue
             storeInHistory:(shouldStore ? shouldStore.boolValue : YES)
                        ttl:ttl
            withReplication:(replicate ? replicate.boolValue : YES)
                   metadata:metadata
            queryParameters:queryParam
                 completion:block];
    }];
    
    return ^PNPublishSizeAPICallBuilder * {
        return builder;
    };
}


#pragma mark - Files message

- (void)publishFileMessageWithRequest:(PNPublishFileMessageRequest *)request
                           completion:(PNPublishCompletionBlock)block {
    
    if (!request.retried) {
        request.sequenceNumber = [self.sequenceManager nextSequenceNumber:YES];
    }
    
    request.useRandomInitializationVector = self.configuration.shouldUseRandomInitializationVector;
    request.cipherKey = self.configuration.cipherKey;
    
    PNLogAPICall(self.logger, @"<PubNub::API> Publish '%@' file message to '%@' channel%@%@%@",
                 (request.identifier ?: @"<error>"),
                 (request.channel ?: @"<error>"),
                 (request.metadata ? [NSString stringWithFormat:@" with metadata (%@)",
                                      request.metadata] : @""),
                 (!request.shouldStore ? @" which won't be saved in history" : @""),
                 [NSString stringWithFormat:@": %@", (request.preFormattedMessage ?: @"<error>")]);
    
    __weak __typeof(self) weakSelf = self;
    
    [self performRequest:request withCompletion:^(PNPublishStatus *status) {
        if (block && status.isError) {
            status.retryBlock = ^{
                request.retried = YES;
                [weakSelf publishFileMessageWithRequest:request completion:block];
            };
        }
        
        if (block) {
            block(status);
        }
    }];
}

#pragma mark - Publish with request

- (void)publishWithRequest:(PNPublishRequest *)request completion:(PNPublishCompletionBlock)block {
    if (!request.retried) {
        request.sequenceNumber = [self.sequenceManager nextSequenceNumber:YES];
    }
    
    request.useRandomInitializationVector = self.configuration.shouldUseRandomInitializationVector;
    request.cipherKey = self.configuration.cipherKey;

    PNLogAPICall(self.logger, @"<PubNub::API> Publish%@ message to '%@' channel%@%@%@",
                 (request.shouldCompress ? @" compressed" : @""),
                 (request.channel ?: @"<error>"),
                 (request.metadata ? [NSString stringWithFormat:@" with metadata (%@)",
                                      request.metadata] : @""),
                 (!request.shouldStore ? @" which won't be saved in history" : @""),
                 (!request.shouldCompress ? [NSString stringWithFormat:@": %@",
                                             (request.message ?: @"<error>")] : @"."));
    
    __weak __typeof(self) weakSelf = self;
    
    [self performRequest:request withCompletion:^(PNPublishStatus *status) {
        if (block && status.isError) {
            status.retryBlock = ^{
                request.retried = YES;
                [weakSelf publishWithRequest:request completion:block];
            };
        }
        
        if (block) {
            block(status);
        }
    }];
}


#pragma mark - Plain message publish

- (void)publish:(id)message
         toChannel:(NSString *)channel
    withCompletion:(PNPublishCompletionBlock)block {

    [self publish:message toChannel:channel withMetadata:nil completion:block];
}

- (void)publish:(id)message
       toChannel:(NSString *)channel
    withMetadata:(NSDictionary<NSString *, id> *)metadata
      completion:(PNPublishCompletionBlock)block {
    
    [self publish:message toChannel:channel compressed:NO withMetadata:metadata completion:block];
}

- (void)publish:(id)message
         toChannel:(NSString *)channel
        compressed:(BOOL)compressed
    withCompletion:(PNPublishCompletionBlock)block {
    
    [self publish:message
        toChannel:channel
       compressed:compressed
     withMetadata:nil
       completion:block];
}

- (void)publish:(id)message
       toChannel:(NSString *)channel
      compressed:(BOOL)compressed
    withMetadata:(NSDictionary<NSString *, id> *)metadata
      completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
         toChannel:channel
    storeInHistory:YES
        compressed:compressed
      withMetadata:metadata
        completion:block];
}

- (void)publish:(id)message
         toChannel:(NSString *)channel
    storeInHistory:(BOOL)shouldStore
    withCompletion:(PNPublishCompletionBlock)block {
    
    [self publish:message
         toChannel:channel
    storeInHistory:shouldStore
      withMetadata:nil
        completion:block];
}

- (void)publish:(id)message
         toChannel:(NSString *)channel
    storeInHistory:(BOOL)shouldStore
      withMetadata:(NSDictionary<NSString *, id> *)metadata
        completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
         toChannel:channel
    storeInHistory:shouldStore
        compressed:NO
      withMetadata:metadata
        completion:block];
}

- (void)publish:(id)message
         toChannel:(NSString *)channel
    storeInHistory:(BOOL)shouldStore
        compressed:(BOOL)compressed
    withCompletion:(PNPublishCompletionBlock)block {

    [self publish:message
         toChannel:channel
    storeInHistory:shouldStore
        compressed:compressed
      withMetadata:nil
        completion:block];
}

- (void)publish:(id)message
         toChannel:(NSString *)channel
    storeInHistory:(BOOL)shouldStore
        compressed:(BOOL)compressed
      withMetadata:(NSDictionary<NSString *, id> *)metadata
        completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:nil
       storeInHistory:shouldStore
           compressed:compressed
         withMetadata:metadata
           completion:block];
}


#pragma mark - Composite message publish

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
       withCompletion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
         withMetadata:nil
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
           compressed:NO
         withMetadata:metadata
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
           compressed:(BOOL)compressed
       withCompletion:(PNPublishCompletionBlock)block {

    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
           compressed:compressed
         withMetadata:nil
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
           compressed:(BOOL)compressed
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
       storeInHistory:YES
           compressed:compressed
         withMetadata:metadata
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
       storeInHistory:(BOOL)shouldStore
       withCompletion:(PNPublishCompletionBlock)block {

    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
       storeInHistory:shouldStore
         withMetadata:nil
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
       storeInHistory:(BOOL)shouldStore
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
       storeInHistory:shouldStore
           compressed:NO
         withMetadata:metadata
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
       storeInHistory:(BOOL)shouldStore
           compressed:(BOOL)compressed
       withCompletion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
       storeInHistory:shouldStore
           compressed:compressed
         withMetadata:nil
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
       storeInHistory:(BOOL)shouldStore
           compressed:(BOOL)compressed
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNPublishCompletionBlock)block {
    
    [self publish:message
            toChannel:channel
    mobilePushPayload:payloads
       storeInHistory:shouldStore
                  ttl:nil
           compressed:compressed
      withReplication:YES
             metadata:metadata
      queryParameters:nil
           completion:block];
}

- (void)publish:(id)message
            toChannel:(NSString *)channel
    mobilePushPayload:(NSDictionary<NSString *, id> *)payloads
       storeInHistory:(BOOL)shouldStore
                  ttl:(NSNumber *)ttl
           compressed:(BOOL)compressed
      withReplication:(BOOL)replicate
             metadata:(NSDictionary<NSString *, id> *)metadata
      queryParameters:(NSDictionary *)queryParameters
           completion:(PNPublishCompletionBlock)block {

    PNPublishRequest *request = [PNPublishRequest requestWithChannel:channel];
    request.arbitraryQueryParameters = queryParameters;
    request.ttl = ttl.unsignedIntegerValue;
    request.replicate = replicate;
    request.compress = compressed;
    request.metadata = metadata;
    request.payloads = payloads;
    request.store = shouldStore;
    request.message = message;
                                 
    [self publishWithRequest:request completion:block];
}


#pragma mark - Signal

- (void)signal:(id)message
           channel:(NSString *)channel
    withCompletion:(PNSignalCompletionBlock)block {
    
    [self signal:message channel:channel withQueryParameters:nil completion:block];
}

- (void)signal:(id)message
                channel:(NSString *)channel
    withQueryParameters:(NSDictionary *)queryParameters
             completion:(PNSignalCompletionBlock)block {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __weak __typeof(self) weakSelf = self;
    
    if (@available(macOS 10.10, iOS 8.0, *)) {
        if (self.configuration.applicationExtensionSharedGroupIdentifier) {
            queue = dispatch_get_main_queue();
        }
    }
    
    dispatch_async(queue, ^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        NSError *signalError = nil;
        NSString *messageForSignal = [PNJSON JSONStringFrom:message withError:&signalError];
        PNRequestParameters *parameters = [PNRequestParameters new];
        [parameters addQueryParameters:queryParameters];
        
        if (channel.length) {
            [parameters addPathComponent:[PNString percentEscapedString:channel]
                          forPlaceholder:@"{channel}"];
        }
        
        if (([messageForSignal isKindOfClass:[NSString class]] && messageForSignal.length) ||
            messageForSignal) {
            
            [parameters addPathComponent:[PNString percentEscapedString:messageForSignal]
                          forPlaceholder:@"{message}"];
        }
        
        PNLogAPICall(strongSelf.logger, @"<PubNub::API> Signal to '%@' channel.",
                     (channel ?: @"<error>"));
        
        [strongSelf processOperation:PNSignalOperation
                      withParameters:parameters
                                data:nil
                     completionBlock:^(PNStatus *status) {
                         
            if (status.isError) {
                status.retryBlock = ^{
                    [weakSelf signal:message
                             channel:channel
                 withQueryParameters:queryParameters
                          completion:block];
                };
            }

            [weakSelf callBlock:block status:YES withResult:nil andStatus:status];
        }];
    });
}


#pragma mark - Message helper

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
       withCompletion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message toChannel:channel withMetadata:nil completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
             compressed:NO
           withMetadata:metadata
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
           compressed:(BOOL)compressMessage
       withCompletion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
             compressed:compressMessage
           withMetadata:nil
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
           compressed:(BOOL)compressMessage
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
             compressed:compressMessage
         storeInHistory:YES
           withMetadata:metadata
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
       storeInHistory:(BOOL)shouldStore
       withCompletion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
         storeInHistory:shouldStore
           withMetadata:nil
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
       storeInHistory:(BOOL)shouldStore
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
             compressed:NO
         storeInHistory:shouldStore
           withMetadata:metadata
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
           compressed:(BOOL)compressMessage
       storeInHistory:(BOOL)shouldStore
       withCompletion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
             compressed:compressMessage
         storeInHistory:shouldStore
           withMetadata:nil
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
           compressed:(BOOL)compressMessage
       storeInHistory:(BOOL)shouldStore
         withMetadata:(NSDictionary<NSString *, id> *)metadata
           completion:(PNMessageSizeCalculationCompletionBlock)block {
    
    [self sizeOfMessage:message
              toChannel:channel
             compressed:compressMessage
         storeInHistory:shouldStore
                    ttl:nil
        withReplication:YES
               metadata:metadata
        queryParameters:nil
             completion:block];
}

- (void)sizeOfMessage:(id)message
            toChannel:(NSString *)channel
           compressed:(BOOL)compressMessage
       storeInHistory:(BOOL)shouldStore
                  ttl:(NSNumber *)ttl
      withReplication:(BOOL)replicate
             metadata:(NSDictionary<NSString *, id> *)metadata
      queryParameters:(NSDictionary *)queryParameters
           completion:(PNMessageSizeCalculationCompletionBlock)block {
    
    if (block) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        NSUInteger nextSequenceNumber = [self.sequenceManager nextSequenceNumber:NO];
        __weak __typeof(self) weakSelf = self;

        if (@available(macOS 10.10, iOS 8.0, *)) {
            if (self.configuration.applicationExtensionSharedGroupIdentifier) {
                queue = dispatch_get_main_queue();
            }
        }
        
        dispatch_async(queue, ^{
            NSError *publishError = nil;
            NSString *messageForPublish = [PNJSON JSONStringFrom:message withError:&publishError];
            NSString *metadataForPublish = nil;
            NSData *publishData = nil;
            
            // Silence static analyzer warnings.
            // Code is aware about this case and at the end will simply call on 'nil' object method.
            // In most cases if referenced object become 'nil' it mean what there is no more need in
            // it and probably whole client instance has been deallocated.
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
            // Encrypt message in case if serialization to JSON was successful.
            if (!publishError) {
                // Try perform user message encryption.
                messageForPublish = [self encryptedMessage:messageForPublish
                                             withCipherKey:self.configuration.cipherKey
                                randomInitializationVector:self.configuration.shouldUseRandomInitializationVector
                                                     error:&publishError];
            }
            
            if (metadata) {
                metadataForPublish = [PNJSON JSONStringFrom:metadata withError:&publishError];
            }
            
            PNRequestParameters *parameters = [self requestParametersForMessage:messageForPublish
                                                                      toChannel:channel
                                                                     compressed:compressMessage
                                                                 storeInHistory:shouldStore
                                                                            ttl:ttl
                                                                      replicate:replicate
                                                                       metadata:metadataForPublish 
                                                                 sequenceNumber:nextSequenceNumber
                                                                queryParameters:queryParameters];
            
            if (compressMessage) {
                NSData *messageData = [messageForPublish dataUsingEncoding:NSUTF8StringEncoding];
                NSData *compressedBody = [PNGZIP GZIPDeflatedData:messageData];
                publishData = (compressedBody?: [@"" dataUsingEncoding:NSUTF8StringEncoding]);
            }
            
            NSInteger size = [weakSelf packetSizeForOperation:PNPublishOperation
                                               withParameters:parameters data:publishData];
            
            pn_dispatch_async(weakSelf.callbackQueue, ^{
                block(size);
            });
            #pragma clang diagnostic pop
        });
    }
}


#pragma mark - Handlers

- (void)handlePublishBuilderExecutionWithFlags:(NSArray<NSString *> *)flags 
                                    parameters:(NSDictionary *)parameters {
    
    id message = parameters[NSStringFromSelector(@selector(message))];
    NSString *channel = parameters[NSStringFromSelector(@selector(channel))];
    NSDictionary *payloads = parameters[NSStringFromSelector(@selector(payloads))];
    NSNumber *shouldStore = parameters[NSStringFromSelector(@selector(shouldStore))];
    NSNumber *ttl = parameters[NSStringFromSelector(@selector(ttl))];
    if (shouldStore && !shouldStore.boolValue) { ttl = nil; }
    NSNumber *compressed = parameters[NSStringFromSelector(@selector(compress))];
    NSNumber *replicate = parameters[NSStringFromSelector(@selector(replicate))];
    NSDictionary *metadata = parameters[NSStringFromSelector(@selector(metadata))];
    
    [self publish:message
        toChannel:channel
    mobilePushPayload:payloads
   storeInHistory:(shouldStore ? shouldStore.boolValue : YES)
              ttl:ttl
       compressed:compressed.boolValue
  withReplication:(replicate ? replicate.boolValue : YES)
         metadata:metadata
  queryParameters:parameters[@"queryParam"]
       completion:parameters[@"block"]];
}


#pragma mark - Misc

- (PNRequestParameters *)requestParametersForMessage:(NSString *)message
                                           toChannel:(NSString *)channel
                                          compressed:(BOOL)compressMessage
                                      storeInHistory:(BOOL)shouldStore
                                                 ttl:(NSNumber *)ttl
                                           replicate:(BOOL)replicate
                                            metadata:(NSString *)metadata
                                      sequenceNumber:(NSUInteger)sequenceNumber
                                     queryParameters:(NSDictionary *)queryParameters {
    
    PNRequestParameters *parameters = [PNRequestParameters new];

    [parameters addQueryParameters:queryParameters];

    if (channel.length) {
        [parameters addPathComponent:[PNString percentEscapedString:channel]
                      forPlaceholder:@"{channel}"];
    }

    if (!shouldStore) {
        [parameters addQueryParameter:@"0" forFieldName:@"store"];
    }

    if (ttl) {
        [parameters addQueryParameter:ttl.stringValue forFieldName:@"ttl"];
    }

    if (!replicate) {
        [parameters addQueryParameter:@"true" forFieldName:@"norep"];
    }

    if (([message isKindOfClass:[NSString class]] && message.length) || message) {
        id targetMessage = !compressMessage ? [PNString percentEscapedString:message] : @"";
        [parameters addPathComponent:targetMessage forPlaceholder:@"{message}"];
    }
    
    if ([metadata isKindOfClass:[NSString class]] && metadata.length) {
        [parameters addQueryParameter:[PNString percentEscapedString:metadata]
                         forFieldName:@"meta"];
    }
    
    [parameters addQueryParameter:@(sequenceNumber).stringValue forFieldName:@"seqn"];
    
    return parameters;
}

- (NSDictionary<NSString *, id> *)mergedMessage:(id)message
                          withMobilePushPayload:(NSDictionary<NSString *, id> *)payloads {

    // Convert passed message to mutable dictionary into which required by push notification
    // delivery service provider data will be added.
    NSDictionary *originalMessage = message ?: @{};
    if (message && ![message isKindOfClass:[NSDictionary class]]) {
        originalMessage = @{ @"pn_other": message };
    }

    NSMutableDictionary *mergedMessage = [originalMessage mutableCopy];

    for (NSString *pushProviderType in payloads) {
        id payload = payloads[pushProviderType];
        NSString *providerKey = pushProviderType;

        if (![pushProviderType hasPrefix:@"pn_"]) {
            providerKey = [NSString stringWithFormat:@"pn_%@", pushProviderType];

            if ([pushProviderType isEqualToString:@"aps"]) {
                payload = @{pushProviderType:payload};
                providerKey = @"pn_apns";
            }
        }

        [mergedMessage setValue:payload forKey:providerKey];
    }
    
    return [mergedMessage copy];
}

- (NSString *)encryptedMessage:(NSString *)message
                 withCipherKey:(NSString *)key
    randomInitializationVector:(BOOL)randomIV
                         error:(NSError **)error {
    
    NSString *encryptedMessage = message;

    if (key.length) {
        NSData *JSONData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSString *JSONString = [PNAES encrypt:JSONData
                                 withRandomIV:randomIV
                                    cipherKey:key
                                     andError:error];

        if (*error == nil) {
            // PNAES encryption output is NSString which is valid JSON object from PubNub
            // service perspective, but it should be decorated with " (this done internally
            // by helper when it need to create JSON string).
            encryptedMessage = [PNJSON JSONStringFrom:JSONString withError:error];
        } else {
            encryptedMessage = nil;
        }
    }
    
    return encryptedMessage;
}

#pragma mark -


@end
