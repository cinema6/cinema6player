package com.cinema6.renderer.events
{
	import flash.events.Event;
	
	public class StateChangeEvent extends Event
	{
		private var _data:Number = 0;
		private var _relayEventName:String;
		
		public function StateChangeEvent(data:Number, relayEventName:String = null)
		{
			super("onStateChange", false, false);
			
			_data = data;
			_relayEventName = relayEventName;
		}
		
		public function get data():Number
		{
			return _data;
		}
		
		public function get relayEventName():String
		{
			return _relayEventName;
		}
	}
}