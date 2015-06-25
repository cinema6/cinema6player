package com.cinema6.renderer.main
{
	import com.cinema6.renderer.utils.StringUtils;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;

	public class VastObjectManager
	{
		var _vastObjects:Array = new Array;
		var _vastCompaions:Array = new Array;
		private var _pixels:Object = {"impression": new Array, "start": new Array, "firstQuartile": new Array, "midpoint": new Array, "thirdQuartile": new Array, "complete": new Array, "click": new Array};

		public function VastObjectManager(wrapper:XML = null):void
		{
			setWrapper(wrapper);
		}

		public function setWrapper(wrapper:XML = null):void
		{
			var text:String = "";

			if (wrapper)
			{
				text = StringUtils.filterPixel(text);

				var creative:XML = wrapper.Creatives..Linear[0];

				for each (var impression:XML in wrapper.Impression)
				{
					text = impression.text();

					text = StringUtils.filterPixel(text);

					_pixels.start.push(text);
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

				for each (var clickTracking:XML in creative.VideoClicks.ClickTracking)
				{
					var clickTrackingUrl:String = clickTracking.text();

					clickTrackingUrl = StringUtils.filterPixel(clickTrackingUrl);

					_pixels.click.push(clickTrackingUrl);
				}

				var companions:XML = wrapper.Creatives..CompanionAds[0];
				if (companions) {
					for each (var companion:XML in companions.Companion) {
						var c:Companion = new Companion(companion);
						_vastCompaions.push(c);
					}
				}
			}
		}

		public function init(xml:XML):void
		{
			for each (var inline:XML in xml.Ad.InLine)
			{
				var vo:VastObject = new VastObject(inline);
				vo.mergePixels(_pixels);
				vo.mergeCompanions(_vastCompaions);

				_vastObjects.push(vo);
			}
		}

		public function get vastObjects():Array
		{
			return _vastObjects;
		}
	}
}