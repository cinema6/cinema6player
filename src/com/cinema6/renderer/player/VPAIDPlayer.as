package com.cinema6.renderer.player
{
	import com.cinema6.renderer.main.VastObject;
	import com.cinema6.renderer.events.StateChangeEvent;
	import com.cinema6.renderer.vpaid.VPAIDConstant;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.system.Security;
	import flash.external.ExternalInterface;
	
	public class VPAIDPlayer extends Sprite
	{	
		private var _volume:Number = 100;
		private var _width:Number = 0;
		private var _height:Number = 0;
				
		private var _vastObject:VastObject;
		private var _vpaid:*;
		private var _duration:Number = 0;
		private var _playerId:String = '';
		
		public function VPAIDPlayer(vpaidLoader:Loader, vastObject:VastObject, _initAdWidth:Number, _initAdHeight:Number, playerId:String)
		{
			_playerId = playerId;
			this.addChild(vpaidLoader);
			
			_vastObject = vastObject;
			_vpaid = Object(vpaidLoader.content).getVPAID();
			_width = _initAdWidth;
			_height = _initAdHeight;
			_duration = 0;
		}
		
		public function init(apiObj:Object = null):void{
			_vpaid.handshakeVersion("1.1.0");
			log("adding events listeners");
			_vpaid.addEventListener(VPAIDConstant.AD_LOADED, onAdLoaded);
			_vpaid.addEventListener(VPAIDConstant.AD_IMPRESSION, onAdImpression);
			_vpaid.addEventListener(VPAIDConstant.AD_STOPPED, onAdStopped);
			_vpaid.addEventListener(VPAIDConstant.AD_PAUSED, onAdPaused);
			_vpaid.addEventListener(VPAIDConstant.AD_PLAYING, onAdPlaying);
			_vpaid.addEventListener(VPAIDConstant.AD_ERROR, onAdError);
			_vpaid.addEventListener(VPAIDConstant.AD_STARTED, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_VIDEO_START, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_VIDEO_FIRST_QUARTILE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_VIDEO_MIDPOINT, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_VIDEO_THIRD_QUARTILE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_VIDEO_COMPLETE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_REMAINING_TIME_CHANGE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_LOG, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_USER_ACCEPT_INVITATION, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_EXPANDED_CHANGE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_LINEAR_CHANGE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_USER_MINIMIZE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_USER_CLOSE, onVPAIDEvent);
			_vpaid.addEventListener(VPAIDConstant.AD_CLICK_THRU, onVPAIDEvent);
			
			if (_vastObject.adParameters && _vastObject.adParameters.length > 0){
				if (_vastObject.adParameters.charAt(0) == "{"){
					apiObj = _vastObject.adParameters;
				}
			}
			
			_vpaid.initAd(_width, _height, "normal", 0, apiObj, null);
			
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback("getAdProperties", getAdProperties);
					ExternalInterface.addCallback("setVolume", setVolume);
					ExternalInterface.addCallback("resumeAd", resumeVideo);
					ExternalInterface.addCallback("pauseAd", pauseVideo);
					ExternalInterface.addCallback("stopAd", stopVideo);
					ExternalInterface.addCallback("startAd", startAd);
				} catch (e:Error) {
				}
			}
		}
		
		private function getAdProperties():Object {		
			return {
				width: _width,
				height : _height, 
				adLinear: _vpaid.adLinear,
				adExpanded: _vpaid.adExpanded,
				adRemainingTime: _vpaid.adRemainingTime,
				adVolume: _vpaid.adVolume,
				adCurrentTime: getCurrentTime(),
				adDuration: getDuration()
			}
		}
		
		private function startAd():void {
			_vpaid.startAd();
		}
		
		protected function onAdLoaded(e:Event):void {
			log("vpaid ad onAdLoaded");
			
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
		}
		
		protected function onAdImpression(e:Event):void {
			log("vpaid ad onAdImpression");
			
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
			
			dispatchEvent(new Event("onReady"));
			dispatchEvent(new StateChangeEvent(5));
		}
		
		protected function onAdError(e:Event):void {
			log("vpaid ad onAdError");
						
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
			
			dispatchEvent(new StateChangeEvent(0));
		}
		
		protected function onAdStopped(e:Event):void {
			log("vpaid ad onAdStopped");
			
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
						
			dispatchEvent(new StateChangeEvent(0));
		}
		
		protected function onAdPlaying(e:Event):void {
			log("vpaid ad onAdPlaying");
						
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
			
			dispatchEvent(new StateChangeEvent(1));
		}
		
		protected function onAdPaused(e:Event):void {
			log("vpaid ad onAdPaused");
						
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
			
			dispatchEvent(new StateChangeEvent(2));
		}
		
		protected function onVPAIDEvent(e:Event):void {
			log("vpaid ad onVPAIDEvent:" + e.type);
			
			ExternalInterface.call('postMessage', '{ "__vpaid__" : { "type" : "' + e.type + '", "id" : "' + _playerId + '" } }', '*');
						
			dispatchEvent(new StateChangeEvent(6, e.type));
			
			if (e.type == VPAIDConstant.AD_REMAINING_TIME_CHANGE && _duration == 0){
				_duration = _vpaid.adRemainingTime;
			}
		}
		
		public function cueVideoById(url:String):void
		{
			//do nothing here;
		}
		
		public function playVideo():void
		{
			//do nothing here;
		}
		
		public function stopVideo():void
		{
			_vpaid.stopAd();
		}
		
		public function pauseVideo():void
		{
			_vpaid.pauseAd();
		}
		
		public function resumeVideo():void
		{
			_vpaid.resumeAd();
		}
		
		public function setSize(width:Number, height:Number):void
		{
			_vpaid.resizeAd(width, height, "normal");
		}
		
		public function setVolume(num:Number):void
		{
			if (num > 1)
				num = num / 100;
			
			_vpaid.adVolume = num;
		}
		
		public function getVolume():Number
		{
			return _vpaid.adVolume * 100;
		}
		
		public function getCurrentTime():Number
		{
			if (_duration <= 0)
				return 0;
			
			return _duration - _vpaid.adRemainingTime;
		}
		
		public function getDuration():Number
		{
			if (_duration <= 0){
				_duration = _vpaid.adRemainingTime;
			}
			
			if (isNaN(_duration)){
				_duration = 0;
			}
			
			return _duration;
		}
		
		private function log(msg:String):void {
			trace("Cinema6:" + msg);
			
			if (ExternalInterface.available) {
				try{
					ExternalInterface.call("console.log", "Cinema6:" + msg);
				}catch(e:Error){}
			}
		}
	}
}