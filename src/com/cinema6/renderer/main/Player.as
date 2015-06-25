package com.cinema6.renderer.main {
	import com.cinema6.renderer.player.VideoPlayer;
	import com.cinema6.renderer.player.VPAIDPlayer;
	import com.cinema6.renderer.tracker.PixelTracker;
	import com.cinema6.renderer.utils.NavigatorUtils;
	import com.cinema6.renderer.utils.NumberUtils;
	import com.cinema6.renderer.utils.StringUtils;
	import com.cinema6.renderer.vpaid.VPAIDConstant;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.text.*;
	import flash.utils.Timer;
	
	public class Player extends MovieClip {
		private static var _mainPlayer:Player;
		
		//**** stage objects***//
		public var _black:Sprite = new Sprite();
		
		private var _adPlayer:Object;
		private var _activePlayer:Object;
		
		private var _vastVideo:VideoObject;
		private var _activeVideo:VideoObject;
		
		private var _adLoader:Loader = new Loader();
		
		public var _volume:Number = 100;
		
		private var _initAdWidth:Number = -1;
		private var _initAdHeight:Number = -1;
		
		private var _startFired:Boolean = false;
		private var _firstQuartileFired:Boolean = false;
		private var _midpointFired:Boolean = false;
		private var _thirdQuartileFired:Boolean = false;
		private var _completeFired:Boolean = false;
		private var _progressFired:Object = {};
		
		private var _timer:Timer;
		private var _adXmlUrl:String;
		
		private var _videoIds:Array = new Array;
		private var _vastObjectManager:VastObjectManager;
		
		private var _destory:Boolean = false;
		private var _apiObj:Object = null;
		
		private var _vpaidTimer:Timer;
		private var _destroyTimer:Timer;
		private var _params:Object = { };
		
		private var _playerId:String = '';
		
		public function Player():void {
			_mainPlayer = this;
			
			Security.allowDomain("*");
			
			this.visible = false;
			
			_black.graphics.clear();
			_black.graphics.beginFill(0x000000);
			_black.graphics.drawRect(0, 0, 1, 1);
			_black.graphics.endFill();
			
			addChild(_black);
			
			PixelTracker.enable();
			
			if (this.loaderInfo.parameters) {
				if (this.loaderInfo.parameters.adXmlUrl) {
					_adXmlUrl = this.loaderInfo.parameters.adXmlUrl;
				}
				
				if (this.loaderInfo.parameters.playerId) {
					_playerId = this.loaderInfo.parameters.playerId;
				}
				
				for (var param:String in this.loaderInfo.parameters) {
					if (param.indexOf("params.") == 0) {
						_params[param] = this.loaderInfo.parameters[param];
					}
				}
			}
			
			stage.addEventListener(Event.RESIZE, onStageResize);
			onStageResize(null);
			
			ExternalInterface.addCallback("isCinema6player", isCinema6player);
			ExternalInterface.addCallback("getDisplayBanners", getDisplayBanners);
			ExternalInterface.addCallback("loadAd", loadAd);
			
			if (_adXmlUrl) {
				Security.allowDomain(_adXmlUrl);
				
				var loader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onAdUrlComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onAdUrlFailed);
				log("loading from " + StringUtils.filterPixel(_adXmlUrl));
				loader.load(new URLRequest(StringUtils.filterPixel(_adXmlUrl)));
				
				this.visible = true;
			} else {
				endPlayer(true);
			}
		}
		
		private function checkLoadStatus(e:Event):void {
			if (loadPercent >= 1) {
				removeEventListener(Event.ENTER_FRAME, checkLoadStatus);
				
				try {
					ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "onAPIReady", "id" : "' + _playerId + '" } }', '*');
				} catch (e:Error) {
				}
			}
		}
		
		protected function get loadPercent():Number {
			return root.loaderInfo.bytesLoaded / root.loaderInfo.bytesTotal;
		}
		
		private function isCinema6player():Boolean {
			return true;
		}
		
		private function getDisplayBanners():Array {
			return _vastVideo.vastObject.getCompanions();
		}
		
		private function setPlayerSize(width:Number, height:Number):void {
			positionAd(width, height);
		}
		
		private function onAdUrlComplete(event:Event, apiMode:Boolean = false, vastString:String = null):void {
			log("onAdUrlComplete");
			
			var xml:XML;
			
			try {
				if (vastString != null) {
					xml = new XML(vastString);
					
					log("onAdUrlComplete:" + xml);
				} else {
					xml = new XML(event.target.data);
				}
			} catch (e:Error) {
				log("problem parsing xml at:" + _adXmlUrl);
			}
			
			var hasWrapper:Boolean = false;
			
			for each (var wrapper:XML in xml.Ad.Wrapper) {
				hasWrapper = true;
				_adXmlUrl = wrapper.VASTAdTagURI.text();
				
				if (!_vastObjectManager) {
					_vastObjectManager = new VastObjectManager(wrapper);
				} else {
					_vastObjectManager.setWrapper(wrapper);
				}
				
				break;
			}
			
			if (hasWrapper) {
				var loader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onAdUrlComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onAdUrlFailed);
				log("loading from " + StringUtils.filterPixel(_adXmlUrl));
				loader.load(new URLRequest(StringUtils.filterPixel(_adXmlUrl)));
				return;
			} else {
				if (!_vastObjectManager) {
					_vastObjectManager = new VastObjectManager();
				}
			}
			_vastObjectManager.init(xml);
			
			for each (var vo:VastObject in _vastObjectManager.vastObjects) {
				_videoIds.push(new VideoObject(vo));
			}
			
			//if default ad is presented
			if (_videoIds.length > 0) {
				var idNum:Number = NumberUtils.getRandomNum(0, _videoIds.length - 1);
				_vastVideo = _videoIds[idNum];
				
				if (_vastVideo.vastObject.isVPAID) {
					if (ExternalInterface.available) {
						try {
							ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "onAdResponse", "id" : "' + _playerId + '" } }', '*');
						} catch (e:Error) {
						}
					}
				} else {
					onLoaderInit();
				}
			} else {
				endPlayer(true);
			}
		}
		
		private function loadAd():void{
			var ldrContext:LoaderContext = new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain);
			ldrContext.checkPolicyFile = true;
			
			Security.allowDomain(_vastVideo.vastObject.mediaFile);
			_adLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderInit);
			_adLoader.load(new URLRequest(_vastVideo.vastObject.mediaFile), ldrContext);
		}
		
		private function onAdUrlFailed(event:IOErrorEvent):void {
			log("loading ad xml from:" + _adXmlUrl + " result in failure");
			
			if (ExternalInterface.available) {
				try {
					ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "onTemplateLoadFailure", "id" : "' + _playerId + '" } }', '*');
				} catch (e:Error) {
				}
			}
			
			endPlayer(true);
		}
		
		private function onLoaderInit(event:Event = null):void {
			log("onLoaderInit event:" + event);
			if (_vastVideo.vastObject.isVPAID) {
				
				ExternalInterface.call("console.log", "initadwidthONINIT" + _initAdWidth);
				
				_adPlayer = new VPAIDPlayer(_adLoader, _vastVideo.vastObject, _initAdWidth, _initAdHeight, _playerId);
				
				_adPlayer.addEventListener("onReady", onAdPlayerReady);
				_adPlayer.addEventListener("onStateChange", onAdPlayerStateChange);
				
				this.addChild(_adPlayer as DisplayObject);
				
				_activePlayer = _adPlayer;
				_activeVideo = _vastVideo;
				
				//_vpaidTimer = new Timer(10000, 1);
				//_vpaidTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onWaitForVPAIDReady);
				//_vpaidTimer.start();
				
				_adPlayer.init(_apiObj);
			} else {
				_adPlayer = new VideoPlayer();
				onAdPlayerReady(null);
				_adPlayer.addEventListener("onStateChange", onAdPlayerStateChange);
			}
		}
		
		/*private function onWaitForVPAIDReady(event:Event):void {
			log("onWaitForVPAIDReady");
			if (_vpaidTimer) {
				_vpaidTimer.stop();
				_vpaidTimer = null;
			}
			
			endPlayer(true);
		}*/
		
		private function onAdPlayerReady(event:Event):void {
			log("onAdPlayerReady:" + _vastVideo.vastObject.mediaFile);
			_adPlayer.cueVideoById(_vastVideo.vastObject.mediaFile);
			
			if (_vpaidTimer) {
				_vpaidTimer.stop();
				_vpaidTimer = null;
			}
			
			PixelTracker.fire(_vastVideo.vastObject.pixels.impression);

			if (ExternalInterface.available) {
				try {
					ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "displayBanners", "id" : "' + _playerId + '" } }', '*');
				} catch (e:Error) {}
			}
			
			positionAd(_initAdWidth, _initAdHeight);
		}
		
		private function onAdPlayerError(event:Event):void {
			log("onAdPlayerError:" + _vastVideo.vastObject.mediaFile);
			
			endPlayer(true);
		}
		
		private function onClicked(event, clickThrough:Boolean = true):void {
			if (clickThrough) {
				var targetURL:URLRequest = new URLRequest(_activeVideo.vastObject.clickThroughUrl);
				NavigatorUtils.navigateToURL(targetURL, "_blank");
			}
			
			PixelTracker.fire(_activeVideo.vastObject.pixels.click);
		}
		
		private function onAdPlayerStateChange(event:Event):void {
			log("onAdPlayerStateChange:" + Object(event).data);
			
			if (Object(event).data == 5) {
				if (!_vastVideo.vastObject.isVPAID) {
					this.addChild(_adPlayer as DisplayObject);
				}
				
				_adPlayer.x = 0;
				_adPlayer.y = 0;
				//init height
				_adPlayer.setSize(_initAdWidth, _initAdHeight);
				_adPlayer.setVolume(_volume);
				
				if (!_vastVideo.vastObject.isVPAID) {
					startProgressTracker(_adPlayer, _vastVideo);
				}
			} else if (Object(event).data == 0) {
				log("video ended");
				endPlayer();
			}
			
			if (Object(event).data == 6) {
				switch (Object(event).relayEventName) {
					case VPAIDConstant.AD_ERROR:
						break;
					case VPAIDConstant.AD_CLICK_THRU:
						PixelTracker.fire(_activeVideo.vastObject.pixels.click);
						break;
					case VPAIDConstant.AD_STARTED:
						if (!_startFired) {
							PixelTracker.fire(_activeVideo.vastObject.pixels.start);
							_startFired = true;
						}
						break;
					case VPAIDConstant.AD_VIDEO_START:
						if (!_startFired) {
							PixelTracker.fire(_activeVideo.vastObject.pixels.start);
							_startFired = true;
						}
						break;
					case VPAIDConstant.AD_VIDEO_FIRST_QUARTILE:
						if (!_firstQuartileFired) {
							PixelTracker.fire(_activeVideo.vastObject.pixels.firstQuartile);
							_firstQuartileFired = true;
						}
						break;
					case VPAIDConstant.AD_VIDEO_MIDPOINT:
						if (!_midpointFired) {
							PixelTracker.fire(_activeVideo.vastObject.pixels.midpoint);
							_midpointFired = true;
						}
						break;
					case VPAIDConstant.AD_VIDEO_THIRD_QUARTILE:
						if (!_thirdQuartileFired) {
							PixelTracker.fire(_activeVideo.vastObject.pixels.thirdQuartile);
							_thirdQuartileFired = true;
						}
						break;
					case VPAIDConstant.AD_VIDEO_COMPLETE:
						if (!_completeFired) {
							PixelTracker.fire(_activeVideo.vastObject.pixels.complete);
							_completeFired = true;
							
							_timer = new Timer(500, 1);
							_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onVPAIDAdVideoComplete);
							_timer.start();
						}
						break;
					case VPAIDConstant.AD_CLICK_THRU:
						PixelTracker.fire(_activeVideo.vastObject.pixels.click);
						break;
					default:
						break;
				}
			}
		}
		
		private function onLinearAdFinish(e:TimerEvent):void {
			_timer.stop();
			_timer = null;
			
			destroy();
		}
		
		private function onVPAIDAdVideoComplete(e:TimerEvent):void {
			_timer.stop();
			_timer = null;
		}
		
		private function startProgressTracker(player:Object, video:VideoObject):void {
			_activePlayer = player;
			_activeVideo = video;
			
			_activePlayer.addEventListener("videoPlayerClicked", onClicked);
			
			positionAd(_initAdWidth, _initAdHeight);
		}
		
		private function getTrackerFunc(player:Object):Function {
			return function() {
				if (player.hasOwnProperty("getCurrentTime") && player.hasOwnProperty("getDuration")) {
					
					if (!_startFired && player.getCurrentTime() > 0) {
						PixelTracker.fire(_activeVideo.vastObject.pixels.start);
						_startFired = true;
					}
					
					var progressValue:String = String(Math.floor(player.getCurrentTime()));
					if (!_progressFired[progressValue] && _activeVideo.vastObject.pixels.progress[progressValue]) {
						PixelTracker.fire(_activeVideo.vastObject.pixels.progress[progressValue]);
						_progressFired[progressValue] = true;
					}
					
					if (!_firstQuartileFired && (player.getCurrentTime() / player.getDuration()) > 0.3) {
						PixelTracker.fire(_activeVideo.vastObject.pixels.firstQuartile);
						_firstQuartileFired = true;
					}
					
					if (!_midpointFired && (player.getCurrentTime() / player.getDuration()) > 0.5) {
						PixelTracker.fire(_activeVideo.vastObject.pixels.midpoint);
						_midpointFired = true;
					}
					
					if (!_thirdQuartileFired && (player.getCurrentTime() / player.getDuration()) > 0.75) {
						PixelTracker.fire(_activeVideo.vastObject.pixels.thirdQuartile);
						_thirdQuartileFired = true;
					}
				}
			}
		}
		
		private function endPlayer(ignorePixel:Boolean = false):void {
			log("endPlayer");
			
			if (!_completeFired && !ignorePixel && _activeVideo) {
				
				PixelTracker.fire(_activeVideo.vastObject.pixels.complete);
				_completeFired = true;
			}
			
			_timer = new Timer(500, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onLinearAdFinish);
			_timer.start();
			
			if (_adPlayer) {
				_adPlayer.removeEventListener("onReady", onAdPlayerReady);
				_adPlayer.removeEventListener("onError", onAdPlayerError);
				_adPlayer.removeEventListener("onStateChange", onAdPlayerStateChange);
			}
			
			if (_activePlayer) {
				try {
					_activePlayer.stopVideo();
				} catch (e:Error) {
				}
			}
		}
		
		private function destroy():void {
			_destroyTimer = new Timer(500, 1);
			_destroyTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onDestoryTimer);
			_destroyTimer.start();
		}
		
		private function onDestoryTimer(e:*):void {
			log("destroy");
			
			try {
				ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "onAllAdsCompleted", "id" : "' + _playerId + '" } }', '*');
			} catch (e:Error) {
			}
			
			this.visible = false;
		}
		
		private function onStageResize(evt:Event):void {
			if (stage.stageWidth != 0 && stage.stageHeight != 0) {
				_initAdWidth = stage.stageWidth;
				_initAdHeight = stage.stageHeight;
				
				positionAd(_initAdWidth, _initAdHeight);
			}
		}
		
		private function positionAd(width:Number, height:Number):void {
			if (_activePlayer && _activePlayer.hasOwnProperty("setSize")) {
				_activePlayer.x = 0;
				_activePlayer.y = 0;
				_activePlayer.setSize(width, height);
			}
			
			_black.width = width;
			_black.height = height;
		}
		
		private function log(msg:String):void {
			trace("Cinema6:" + msg);
			
			if (ExternalInterface.available) {
				try {
					ExternalInterface.call("console.log", "Cinema6:" + msg);
				} catch (e:Error) {
				}
			}
		}
		
		override public function get width():Number {
			return _initAdWidth;
		}
		
		override public function get height():Number {
			return _initAdHeight;
		}
		
		public function get params():Object {
			return _params;
		}
		
		public function get playerId():String {
			return _playerId;
		}
		
		public static function get mainPlayer():Player {
			return _mainPlayer;
		}
	}
}