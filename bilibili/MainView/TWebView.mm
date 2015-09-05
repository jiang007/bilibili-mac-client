//
//  WevViewProvider.m
//  bilibili
//
//  Created by TYPCN on 2015/9/5.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

// 为啥要这样而不是做 provider 类然后继承呢？其实主要是懒。。。加到原来的类就太乱了，不过先 make it works ， Clean 之后再说

#import "TWebView.h"
#import "WebTabView.h"

WKWebViewConfiguration *cfg;

@implementation TWebView

- (void)dealloc{
    [WKwv removeObserver:self forKeyPath:@"title"];
}

- (TWebView *)initWithRequest:(NSURLRequest *)req andDelegate:(id <TWebViewDelegate>)aDelegate{
    if (self.delegate != aDelegate) {
        self.delegate = aDelegate;
    }

    if (NSClassFromString(@"WKWebView")) {
        if(!cfg){
            cfg = [[WKWebViewConfiguration  alloc] init];
        }
        webViewType = tWKWebView;
        WKwv = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:cfg];
        [WKwv setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [WKwv setNavigationDelegate: self];
        [WKwv setUIDelegate: self];
        [WKwv addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    } else {
        webViewType = tWebView;
        wv = [[WebView alloc] init];
        [wv setAutoresizingMask:NSViewMaxYMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable|NSViewMinYMargin];
        [wv setFrameLoadDelegate:self];
        [wv setUIDelegate:self];
        [wv setResourceLoadDelegate:self];
        
    }
    
    if(cfg){
        [NSTimer scheduledTimerWithTimeInterval:0.3
                                         target:self
                                       selector:@selector(loadRequest:)
                                       userInfo:req
                                        repeats:NO];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]){
        if (object == WKwv) {
            [self.delegate onTitleChange:WKwv.title];
        } else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)loadRequest:(NSTimer*)timer{
    NSURLRequest *req = [timer userInfo];
    if(webViewType == tWKWebView){
        [WKwv loadRequest:req];
    }else{
        wv.mainFrameURL = [req.URL absoluteString];
    }
}

- (id)GetWebView{
    if(webViewType == tWKWebView){
        return WKwv;
    }else{
        return wv;
    }
}

- (void)addToView:(NSScrollView *)view{
    if(webViewType == tWKWebView){
        [view setDocumentView:WKwv];
    }else{
        [view setDocumentView:wv];
    }
}

- (void)setFrameSize:(NSRect)newFrame{
    if(webViewType == tWKWebView){
        [WKwv setFrame:newFrame];
    }else{
        [wv setFrame:newFrame];
    }
}

- (void)setURL:(NSString *)url {
    if(webViewType == tWKWebView){
        NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
        [re setURL:[NSURL URLWithString:url]];
        NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [re setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
        [WKwv loadRequest:re];
    }else{
        wv.mainFrameURL = url;
    }
}

- (NSString *)getURL{
    if(webViewType == tWKWebView){
        return [WKwv.URL absoluteString];
    }else{
        return wv.mainFrameURL;
    }
}

- (NSString *)getTitle{
    if(webViewType == tWKWebView){
        return WKwv.title;
    }else{
        return wv.mainFrameTitle;
    }
}

- (void)runJavascript:(NSString *)str{
    if(webViewType == tWKWebView){
        [WKwv evaluateJavaScript:str completionHandler:nil];
    }else{
        [wv stringByEvaluatingJavaScriptFromString:str];
    }
}

- (void)wgoForward{
    if(webViewType == tWKWebView){
        [WKwv goForward];
    }else{
        [wv goForward];
    }
}

- (void)wgoBack{
    if(webViewType == tWKWebView){
        [WKwv goBack];
    }else{
        [wv goBack];
    }
}

#pragma mark WebView delegate

- (BOOL) webView: (WebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request
{
    return [self.delegate shouldStartDecidePolicy: request];
}

- (void) webViewDidStartLoad: (WebView *) webView
{
    [self.delegate didStartNavigation];
}

- (void)webView:(WebView *)sender
didReceiveTitle:(NSString *)title
       forFrame:(WebFrame *)frame{
    [self.delegate didCommitNavigation];
}

- (void) webView: (WebView *) webView didFailLoadWithError: (NSError *) error
{
    [self.delegate failLoadOrNavigation: nil withError: error];
}

- (void) webViewDidFinishLoad: (WebView *) webView
{
    [self.delegate finishLoadOrNavigation: nil];
}

#pragma mark WKWebView delegate

- (void) webView: (WKWebView *) webView decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler
{
    BOOL shouldload = [self.delegate shouldStartDecidePolicy: [navigationAction request]];
    if(shouldload){
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void) webView: (WKWebView *) webView didStartProvisionalNavigation: (WKNavigation *) navigation
{
    [self.delegate didStartNavigation];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [self.delegate didCommitNavigation];
}

- (void) webView:(WKWebView *) webView didFailProvisionalNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self.delegate failLoadOrNavigation:nil withError: error];
}

- (void) webView: (WKWebView *) webView didFailNavigation: (WKNavigation *) navigation withError: (NSError *) error
{
    [self.delegate failLoadOrNavigation:nil withError: error];
}

- (void) webView: (WKWebView *) webView didFinishNavigation: (WKNavigation *) navigation
{
    [self.delegate finishLoadOrNavigation:nil];
}

- (WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures{
    cfg = configuration;
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withRequest:navigationAction.request];
    [browser addTabContents:ct inForeground:YES];
    return [ct GetWebView];
}

- (WebView *)webView:(id)sender createWebViewWithRequest:(NSURLRequest *)request
{
    WebTabView *ct = (WebTabView *)[browser createTabBasedOn:nil withRequest:request];
    [browser addTabContents:ct inForeground:YES];
    return [ct GetWebView];
}
@end