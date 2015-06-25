package com.cinema6.renderer.utils
{
	import com.cinema6.renderer.page.Page;
	import com.cinema6.renderer.main.Player;
	import flash.external.ExternalInterface;
	
	public class StringUtils
	{		
		private static var _page:Page = new Page();
		
		public static function filterPixel(str:String):String
		{
			var temp:String = str;
			
			var timestamp:String = String(new Date().getTime());
			
			temp = temp.split("REPLACE_ME_WITH_A_TIMESTAMP").join(timestamp);
			temp = temp.split("[CACHE_BUSTER]").join(timestamp);
			temp = temp.split("[CACHE_BREAKER]").join(timestamp);
			temp = temp.split("CACHEBUSTER").join(timestamp);
			temp = temp.split("INSERT_RANDOM_NUMBER_HERE").join(timestamp);
			temp = temp.split("[timestamp]").join(timestamp);
			temp = temp.split("[TIMESTAMP]").join(timestamp);
			
			temp = temp.split("[INSERT_PAGE_URL]").join(encodeURIComponent(_page.url));
			temp = temp.split("[referrer_url]").join(encodeURIComponent(_page.url));
			temp = temp.split("[page_url]").join(encodeURIComponent(_page.url));
			temp = temp.split("[page.url]").join(encodeURIComponent(_page.url));
			temp = temp.split("EMBEDDING_PAGE_URL").join(encodeURIComponent(_page.url));
			
			temp = temp.split("[INSERT_PAGE_TITLE]").join(encodeURIComponent(_page.title));
			temp = temp.split("[page.title]").join(encodeURIComponent(_page.title));
			temp = temp.split("[page_title]").join(encodeURIComponent(_page.title));

			temp = temp.split("[VIDEO_WIDTH]").join(Player.mainPlayer.width);
			temp = temp.split("[player_width]").join(Player.mainPlayer.width);
			temp = temp.split("[player.width]").join(Player.mainPlayer.width);
			
			temp = temp.split("[VIDEO_HEIGHT]").join(Player.mainPlayer.height);
			temp = temp.split("[player_height]").join(Player.mainPlayer.height);
			temp = temp.split("[player.height]").join(Player.mainPlayer.height);
			
			temp = temp.split("[domain]").join(_page.domain);
			
			for (var param:String in Player.mainPlayer.params) {
				temp = temp.split("[" + param + "]").join(encodeURIComponent(Player.mainPlayer.params[param]));
			}
			
			return temp;
		}
	}
}