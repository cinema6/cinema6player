package com.cinema6.renderer.player
{
	import com.cinema6.renderer.events.StateChangeEvent;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.utils.Timer;
	import flash.external.ExternalInterface;
	
	public class VideoPlayer extends Sprite
	{
		private const THUMBNAIL_POSITION:Number = 1;
		
		private var _netConnection:NetConnection;
		private var _netStream:NetStream;
		private var _blackScreen:Sprite;
		
		private var _timer:Timer;
		private var _video:Video;
		private var _playing:Boolean = false;
		private var _metaData:Object;
		private var _duration:Number = 0;
		private var _thumb:Boolean = false;
		private var _firstBuffered:Boolean;
		
		private var _overlay:Sprite;
		
		private var _volume:Number = 100;
		private var _width:Number = 0;
		private var _height:Number = 0;
		private var _videoReady:Boolean = false;
		private var _played:Boolean = false;
		
		public function VideoPlayer()
		{
			_blackScreen = new Sprite();
			_blackScreen.graphics.beginFill(0x000000);
			_blackScreen.graphics.drawRect(0, 0, 1, 1);
			_blackScreen.graphics.endFill();
			_blackScreen.visible = false;
			this.addChild(_blackScreen);
			
			_netConnection = new NetConnection();
			_netConnection.connect(null);
			
			_netStream = new NetStream(_netConnection);
			_netStream.soundTransform = new SoundTransform(0);
			_netStream.client = {onMetaData: onMeta};
			_netStream.addEventListener(NetStatusEvent.NET_STATUS, onStatus, false, 0, true);
			
			_video = new Video(_width, _height);
			_video.smoothing = true;
			_video.visible = false;
			this.addChild(_video);
			
			_timer = new Timer(500);
			_timer.addEventListener(TimerEvent.TIMER, onTimerUpdate);
			
			dispatchEvent(new StateChangeEvent(-1));
		}
		
		private function resize():void
		{
			if (_metaData && _metaData.width && _metaData.height)
			{
				var nativeRatio:Number = _metaData.width / _metaData.height;
				var videoRatio:Number = _width / _height;
				var diff:Number = nativeRatio - videoRatio;
				
				if (diff > 0.0001)
				{
					_video.width = _width;
					_video.x = 0;
					var h:Number = Math.round(_metaData.height * _width / _metaData.width);
					_video.height = isNaN(h) ? _height : h;
					var y:Number = Math.round((_height - _video.height) / 2);
					_video.y = isNaN(y) ? 0 : y;
				}
				else if (diff < -0.0001)
				{
					var w:Number = Math.round(_metaData.width * _height / _metaData.height);
					_video.width = isNaN(w) ? _width : w;
					var x:Number = Math.round((_width - _video.width) / 2);
					_video.x = isNaN(x) ? 0 : x;
					_video.height = _height;
					_video.y = 0;
				}
				else
				{
					_video.x = 0;
					_video.y = 0;
					_video.width = _width;
					_video.height = _height;
				}
			}
			else
			{
				_video.x = 0;
				_video.y = 0;
				_video.width = _width;
				_video.height = _height;
			}
			
			_blackScreen.x = 0;
			_blackScreen.y = 0;
			_blackScreen.width = _width;
			_blackScreen.height = _height;
		}
		
		private function onMeta(data:Object):void
		{
			_duration = Number(data.duration);
			_metaData = data;
			
			_blackScreen.visible = true;
		}
		
		private function onTimerUpdate(event:TimerEvent):void
		{
			_videoReady = true;
			this.setVolume(_volume);
			_video.visible = true;
			setSize(_width, _height);
			
			dispatchEvent(new StateChangeEvent(5));
			
			if (_netStream.time > 0 && _played)
			{
				_video.visible = true;
			}
		}
		
		//since we are mimicking youtube cueVideoById loads the url instead
		public function cueVideoById(url:String):void
		{
			Security.allowDomain("*");
			_playing = true;
			_duration = 0;
			
			_video.attachNetStream(_netStream);
			_netStream.play(url);
			
			_blackScreen.addEventListener(MouseEvent.CLICK, function(event:Event)
				{
					dispatchEvent(new Event("videoPlayerClicked"));
				});
			
			_timer.start();
		}
		
		public function stopVideo():void
		{
			_netStream.pause();
			_netStream.seek(0);
			
			dispatchEvent(new StateChangeEvent(0));
			stopTimer();
		}
		
		public function pauseVideo():void
		{
			_netStream.pause();
			dispatchEvent(new StateChangeEvent(2));
		}
		
		public function rewind():void
		{
			_netStream.seek(0);
		}
		
		public function seek(per:Number):void
		{
			var st:Number = Math.min(timeLoaded, int(per * getDuration()));
			_netStream.seek(st);
		}
		
		public function setSize(width:Number, height:Number):void
		{
			_width = width;
			_height = height;
			
				ExternalInterface.call("console.log", "__________________adplayerw" + _width);
				ExternalInterface.call("console.log", "__________________adplayerh" + _height);
			
			if (_videoReady)
			{
				resize();
			}
		}
		
		public function get timeLoaded():Number
		{
			return percentLoaded * getDuration();
		}
		
		public function get percentLoaded():Number
		{
			if (_netStream.bytesLoaded <= 0 || _netStream.bytesTotal <= 0)
				return 0;
			return Math.max(0, Math.min(1, _netStream.bytesLoaded / _netStream.bytesTotal));
		}
		
		public function setVolume(num:Number):void
		{
			if (_videoReady)
			{
				if (num > 1)
					num = num / 100;
				_netStream.soundTransform = new SoundTransform(num);
			}
			
			_volume = num;
		}
		
		public function getVolume():Number
		{
			if (_netStream)
				return _netStream.soundTransform.volume * 100;
			
			return 0;
		}
		
		public function getCurrentTime():Number
		{
			if (_netStream)
				return _netStream.time;
			
			return 0;
		}
		
		public function getDuration():Number
		{
			return _duration;
		}
		
		public function detach():void
		{
			_video.attachNetStream(null);
			_video.clear();
		}
		
		public function close():void
		{
			detach();
			_netStream.close();
		}
		
		private function onStatus(e:NetStatusEvent):void
		{
			trace(e.info.code);
			switch (e.info.code)
			{
				case "NetStream.Play.Start": 
					break;
				case "NetStream.Buffer.Full": 
					break;
				case "NetStream.Play.Stop": 
					dispatchEvent(new StateChangeEvent(0));
					stopTimer();
					break;
				case "NetStream.Buffer.Empty": 
					break;
				case "NetConnection.Connect.Success": 
					break;
				case "NetStream.Play.StreamNotFound": 
				case "NetConnection.Connect.Rejected": 
					dispatchEvent(new Event("onError"));
					break;
				case "NetConnection.Connect.Closed": 
					break;
			}
		}
		
		public function stopTimer():void
		{
			if (_timer)
			{
				_timer.stop();
				_timer == null;
			}
		}
		
		public function destroy():void
		{
			stopTimer();
			close();
			detach();
			
			_netStream.removeEventListener(NetStatusEvent.NET_STATUS, onStatus);
			
			_netConnection.close();
			_netConnection = null;
			_netStream = null;
			_video = null;
		}
	}
}