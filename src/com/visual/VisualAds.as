// Place overlay correctly (top?)
// Make sure we do dynamic loading
// Make VAST/InStream part of PlayFlow

package com.visual {
	import com.google.ads.instream.api.Ad;
	import com.google.ads.instream.api.AdErrorEvent;
	import com.google.ads.instream.api.AdEvent;
	import com.google.ads.instream.api.AdSizeChangedEvent;
	import com.google.ads.instream.api.AdsLoadedEvent;
	import com.google.ads.instream.api.AdsLoader;
	import com.google.ads.instream.api.AdsManager;
	import com.google.ads.instream.api.AdsManagerTypes;
	import com.google.ads.instream.api.AdsRequest;
	import com.google.ads.instream.api.FlashAdsManager;
	import com.google.ads.instream.api.VideoAdsManager;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.media.Video;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	[Event(name="contentPauseRequested", type="flash.events.Event")]
	[Event(name="contentResumeRequested", type="flash.events.Event")]
	
	public class VisualAds extends UIComponent {
		private var loader:AdsLoader;
		private var manager:AdsManager;
		private var requests:Array = [];
		private var internalVideo:Video = null;
		
		public function VisualAds() {
			super();
			this.visible = false;
			this.addEventListener(ResizeEvent.RESIZE, handleChildrenSizes);
			
			// Google IMA Loader
			loader = new AdsLoader();
			loader.addEventListener(AdsLoadedEvent.ADS_LOADED, onAdsLoaded);
			loader.addEventListener(AdErrorEvent.AD_ERROR, trace);
			
			// Add a video element to play within
			internalVideo = new Video();
			internalVideo.smoothing = true;
			internalVideo.deblocking = 1;
			handleChildrenSizes();
			this.addChild(internalVideo);
			internalVideo.visible = false;
		}
		public function push(type:String, url:String, publisherId:String = '', contentId:String = ''):void {
			requests.push({type:type, url:url, publisherId:publisherId, contentId:contentId});
		}
		public function preroll():Boolean {
			return(this.load('video'));
		}
		public function overlay():Boolean {
			return(this.load('overlay'));
		}
		public function postroll():Boolean {
			return(this.load('video'));
		}
		private function load(type:String):Boolean {
			for (var i:int=0; i<requests.length; i++){
				var req:Object = requests[i];
				if(req.type==type) {
					var request:AdsRequest = new AdsRequest();
					request.adType = req.type;
					request.adTagUrl = req.url;
					request.publisherId = req.publisherId;
					request.contentId = req.contentId;
					request.adSlotWidth = this.width;
					request.adSlotHeight = this.height;
					requests.push(request);
					loader.requestAds(request);
					this.visible = true;
					return(true);
				}
			}
			return(false);
		}
		private function onContentPauseRequested(e:AdEvent):void {
			dispatchEvent(new Event('contentPauseRequested'));
		}
		private function onContentResumeRequested(e:AdEvent):void {
			dispatchEvent(new Event('contentResumeRequested'));
		}
		private function onAdError(e:AdErrorEvent):void {
			trace('VisualAd Error:', e.error.errorMessage);
		}
		private function onFlashAdSizeChanged(e:AdSizeChangedEvent):void {
			trace('onFlashAdSizeChanged', e);
		}
		private function onVideoAdComplete(e:AdEvent):void {
			// Remove video element if applicable
			(manager as VideoAdsManager).clickTrackingElement = null; 
			this.internalVideo.visible = false;
			this.internalVideo.clear();
		}
		
		private function onAdsLoaded(e:AdsLoadedEvent):void {
			manager = e.adsManager;
			manager.addEventListener(AdErrorEvent.AD_ERROR, onAdError);
			manager.addEventListener(AdEvent.CONTENT_PAUSE_REQUESTED, onContentPauseRequested);
			manager.addEventListener(AdEvent.CONTENT_RESUME_REQUESTED, onContentResumeRequested);
			
			if (manager.type == AdsManagerTypes.FLASH) {
				var flashAdsManager:FlashAdsManager = e.adsManager as FlashAdsManager;
				flashAdsManager.addEventListener(AdSizeChangedEvent.SIZE_CHANGED, onFlashAdSizeChanged);
				
				var placeHolder:UIComponent = this;
				var point:Point = placeHolder.localToGlobal(new Point(placeHolder.x, placeHolder.y));
				flashAdsManager.x = point.x;
				flashAdsManager.y = point.y;
				flashAdsManager.load();
				flashAdsManager.play(placeHolder);
			} else if (manager.type == AdsManagerTypes.VIDEO) {
				var videoAdsManager:VideoAdsManager = e.adsManager as VideoAdsManager;
				videoAdsManager.addEventListener(AdEvent.COMPLETE, onVideoAdComplete); 
				videoAdsManager.clickTrackingElement = this;
				videoAdsManager.load(this.internalVideo);
				this.internalVideo.visible = true;
				videoAdsManager.play(this.internalVideo);
			} else if (manager.type == AdsManagerTypes.CUSTOM_CONTENT) {
				// Not supported
			}
		}
		
		private function handleChildrenSizes(e:ResizeEvent=null):void {
			trace('handleChildrenSizes');
			if(this&&this.width&&this.internalVideo) {
				this.internalVideo.width = this.width;
				this.internalVideo.height = this.height;
				trace('video width', this.internalVideo.width);
			}
		}
		
	}
}