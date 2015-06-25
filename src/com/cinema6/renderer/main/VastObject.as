package com.cinema6.renderer.main
{
	import com.cinema6.renderer.utils.StringUtils;
	import flash.external.ExternalInterface;

	public class VastObject
	{
		private var _title:String = "";
		private var _adSystem:String = "";
		private var _clickThroughUrl:String = "";
		private var _mediaFile:String = "";
		private var _vastCompaions:Array = new Array;
		private var _isVPAID:Boolean = false;
		private var _countdownDuration:Number = 0;
		private var _adRemainingTimeEnabled:Boolean = true;
		private var _autoPlay:Boolean = false;
		private var _extensions = String;
		private var _adParameters:String;

		private var _pixels:Object = {"impression": new Array, "start": new Array, "firstQuartile": new Array, "midpoint": new Array, "thirdQuartile": new Array, "complete": new Array, "click": new Array, "progress": {}};

		public function VastObject(inline:XML):void
		{
			_title = inline.AdTitle.text();
			_adSystem = inline.AdSystem.text();

			var text:String = "";

			for each (var impression:XML in inline.Impression)
			{
				text = impression.text();

				text = StringUtils.filterPixel(text);

				_pixels.impression.push(text);
			}

			var creative:XML = inline.Creatives..Linear[0];
			
			try{
				_adParameters = String(creative.AdParameters);
			}catch(e:Error){
				_adParameters = null;
			}

			if (creative && creative.TrackingEvents && creative.TrackingEvents.Tracking)
			{
				for each (var tracking:XML in creative.TrackingEvents.Tracking)
				{
					text = tracking.text();

					text = StringUtils.filterPixel(text);

					switch (tracking.@event.toString())
					{
						case "start":
							_pixels.start.push(text);
							break;
						case "firstQuartile":
							_pixels.firstQuartile.push(text);
							break;
						case "midpoint":
							_pixels.midpoint.push(text);
							break;
						case "thirdQuartile":
							_pixels.thirdQuartile.push(text);
							break;
						case "complete":
							_pixels.complete.push(text);
							break;
					}
				}
			}

			for each (var clickThrough:XML in creative.VideoClicks.ClickThrough)
			{
				var click:String = clickThrough.text();

				click = StringUtils.filterPixel(click);

				_clickThroughUrl = click;
			}

			for each (var clickTracking:XML in creative.VideoClicks.ClickTracking)
			{
				var clickTrackingUrl:String = clickTracking.text();

				clickTrackingUrl = StringUtils.filterPixel(clickTrackingUrl);

				_pixels.click.push(clickTrackingUrl);
			}

			for each (var mediaFile:XML in creative.MediaFiles.MediaFile)
			{
				_mediaFile = mediaFile.text();

				var apiFramework:String = mediaFile.@apiFramework;
				var mediaType:String = mediaFile.@type;

				if ((apiFramework && apiFramework == "VPAID") || (mediaType && mediaType == "application/x-shockwave-flash"))
				{
					_isVPAID = true;
				}

				if (_mediaFile.length > 0)
				{
					break;
				}
			}

			var companions:XML = inline.Creatives..CompanionAds[0];

			if (companions) {
				for each (var companion:XML in companions.Companion) {
					var c:Companion = new Companion(companion);

					_vastCompaions.push(c);
				}
			}

			_extensions = String(inline.Extensions);
			if (_adSystem == 'OPTIMATIC'){
				_extensions = inline.Creatives..Linear[0].AdParameters;
			}

			if (inline.Extensions && inline.Extensions.length() > 0)
			{
				for each (var extension:XML in inline.Extensions.Extension)
				{
					if (extension.@type && extension.@type == "GM")
					{
						if (extension.Trackings)
						{
							for each (var trackEvent:XML in extension.Trackings.Tracking)
							{
								if (trackEvent.@event == "progress")
								{
									text = String(trackEvent);
									text = StringUtils.filterPixel(text);

									var progressValue:String = String(Math.floor(Number(trackEvent.@value)));
									if (!_pixels.progress[progressValue])
									{
										_pixels.progress[progressValue] = new Array;
									}

									_pixels.progress[progressValue].push(text);
								}

							}
						}
					}
				}
			}
		}

		private function log(msg:String):void
		{
			trace("Cinema6:" + msg);

			if (ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call("console.log", "Cinema6:" + msg);
				}
				catch (e:Error)
				{
				}
			}
		}

		public function get clickThroughUrl():String
		{
			return _clickThroughUrl;
		}

		public function get title():String
		{
			return _title;
		}

		public function get adSystem():String
		{
			return _adSystem;
		}

		public function get mediaFile():String
		{
			return _mediaFile;
		}

		public function get pixels():Object
		{
			return _pixels;
		}

		public function addPixel(event:String, url:String):void
		{
			_pixels[event].push(url);
		}
		
		public function get adParameters():String {
			return _adParameters;
		}

		public function get isVPAID():Boolean
		{
			return _isVPAID;
		}

		public function mergeCompanions(companions:Array):void
		{
			for each (var c:Companion in companions)
			{
				_vastCompaions.push(c);
			}
		}

		public function mergePixels(pixels:Object):void {
			for (var p:String in pixels) {
				for each (var pp:* in pixels[p]) {
					addPixel(p, pp);
				}
			}
		}

		public function getCompanions():Array
		{
			return _vastCompaions;
		}

		public function get extensions():String{
			return _extensions;
		}

		public function getFirstCompanion():Companion
		{
			if (_vastCompaions.length > 0)
				return _vastCompaions[0] as Companion;

			return null;
		}
	}
}
