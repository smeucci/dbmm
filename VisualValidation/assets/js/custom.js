
$(document).on("change", ".selector", function (e) {
	
	var height = $(document).height();
	var image_height = 195; //145+30+20
	var rows = Math.ceil(height/image_height);
	
	var width = $(document).width();
	var identity_div_width_percent = 16.66666667;
	var image_width = 145; //115+15+15
	var columns = Math.floor((width*(100-identity_div_width_percent)/100)/image_width);
	
	var num = rows*columns;
	
	var label = (e.currentTarget).selectedOptions[0].attributes[0].value;
	var name = (e.currentTarget).selectedOptions[0].value;
	
	$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/get_identity_ajax", 
		   	{	"label": label,
				"name": name,
				"num": num
			}, function (data) {
				
				$('.show-identity').children().remove();
				$('.show-identity').html(data.identity_div);
				
				$('.show-gallery').children().remove();
				$('.show-gallery').html(data.gallery);
				
				$('.btn-next').attr("data-offset", 0);
				$('.btn-prev').attr("data-offset", 0);
				
				
				
			}, "json");
	
});


$(document).on("click", ".start", function (e) {
	
	var height = $(document).height();
	var image_height = 195; //145+30+20
	var rows = Math.ceil(height/image_height);
	
	var width = $(document).width();
	var identity_div_width_percent = 16.66666667;
	var image_width = 145; //115+15+15
	var columns = Math.floor((width*(100-identity_div_width_percent)/100)/image_width);
	
	var num = rows*columns;
	
	$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/home",
			{	"num": num
			},
			function (data) {
				
				$('.centered.welcome').remove();
				$('body').html(data);
		
			});

});


$(document).on("click", ".thumbnail.gallery", function (e) {
	
	if ($(e.currentTarget).hasClass("selected")) {
        		
		$(e.currentTarget).removeClass("selected");
		
	} else {
	  
		$(e.currentTarget).addClass("selected");
		
	}
  
});


$(document).on("dblclick", ".thumbnail.gallery", function (e) {
	
	var image = $(e.currentTarget).attr("data-img");
	var label = $(".identity-div").attr("data-label");
	var box = $(e.currentTarget).attr("data-box");
	var old_image = $(e.currentTarget).attr("data-old");
	
	
	if ($(e.currentTarget).hasClass("lbl-0")) {
		
		var validation = 1;
	        		
		$(e.currentTarget).removeClass("lbl-0");
		$(e.currentTarget).addClass("lbl-1");
		  
		$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/validate_image_ajax",
				{	"image": image,
					"label": label,
					"old_image": old_image,
					"box": box,
					"validation": validation		
				});
		  
			
	} else if ($(e.currentTarget).hasClass("lbl-1")) {
		
		var validation = 0;
		  
		$(e.currentTarget).removeClass("lbl-1");
		$(e.currentTarget).addClass("lbl-0");
		
		$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/validate_image_ajax",
				{	"image": image,
					"label": label,
					"old_image": old_image,
					"box": box,
					"validation": validation		
				});
		
	}
  
});


$(document).on("dblclick", ".identity-img", function (e) {
	
	var label = $(".identity-div").attr("data-label");
	
	if ($(e.currentTarget).hasClass("rmv-0")) {
		
		var remove = 1;
		
		$(e.currentTarget).removeClass("rmv-0");
		$(e.currentTarget).addClass("rmv-1");
		
		$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/remove_identity_ajax",
				{	"label": label,
					"remove": remove,		
				});
		
	} else if ($(e.currentTarget).hasClass("rmv-1")) {
		
		var remove = 0;
		
		$(e.currentTarget).removeClass("rmv-1");
		$(e.currentTarget).addClass("rmv-0");
		
		$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/remove_identity_ajax",
				{	"label": label,
					"remove": remove,		
				});
		
	}
	
})

$(document).on("click", ".btn-next", function (e) {
	
	var height = $(document).height();
	var image_height = 195; //145+30+20
	var rows = Math.ceil(height/image_height);
	
	var width = $(document).width();
	var identity_div_width_percent = 16.66666667;
	var image_width = 145; //115+15+15
	var columns = Math.floor((width*(100-identity_div_width_percent)/100)/image_width);
	
	var num = rows*columns;
	
	
	var label = $(".identity-div").attr("data-label");
	var name = $(".identity-div").attr("data-name");
	//var num = 32;
	var offset = parseInt($(e.currentTarget).attr("data-offset")) + num;
	
		
	$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/get_gallery_images_ajax", 
			{	"label": label,
				"name": name,
				"num": num, 
				"offset": offset
			}, function (data) {
			
				if (parseInt(data.count) != 0) {
					
					$('.show-gallery').children().remove();
					$('.show-gallery').html(data.html);
					
					$('.btn-next').attr("data-offset", offset);
					$('.btn-prev').attr("data-offset", offset);
			
			}
			
			}, "json");
	
});


$(document).on("click", ".btn-prev", function (e) {
	
	var height = $(document).height();
	var image_height = 195; //145+30+20
	var rows = Math.ceil(height/image_height);
	
	var width = $(document).width();
	var identity_div_width_percent = 16.66666667;
	var image_width = 145; //115+15+15
	var columns = Math.floor((width*(100-identity_div_width_percent)/100)/image_width);
	
	var num = rows*columns;
	
	var label = $(".identity-div").attr("data-label");
	var name = $(".identity-div").attr("data-name");
	//var num = 32;
	var offset = parseInt($(e.currentTarget).attr("data-offset")) - num;
	
	if (offset >= 0) {
		
		$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/get_gallery_images_ajax", 
		   	{	"label": label,
				"name": name,
				"num": num, 
				"offset": offset
			}, function (data) {
				
				$('.show-gallery').children().remove();
				$('.show-gallery').html(data.html);
				
				$('.btn-prev').attr("data-offset", offset);
				$('.btn-next').attr("data-offset", offset);
			
			}, "json");
	
	}

});


$(document).on("click", ".btn-export", function (e) {
	
	$.post("http://" + window.location.hostname + window.location.pathname + "/index.php/Pages/export_ajax",
		{}, function () {
			
			$(".progress-bar").attr("aria-valuenow", 100);
			$(".progress-bar").css("width", "100%");
			$(".progress-bar").text("100% Complete");
			
			setTimeout(function () {
				$("#export-modal").modal('hide');
				$(".progress-bar").attr("aria-valuenow", 0);
				$(".progress-bar").css("width", "0%");
				$(".progress-bar").text("");
			}, 1500)
			
		});
	
	t = setTimeout("updateStatus()", 1000);
	
})


function updateStatus(){ 
 
	$.getJSON('http://" + window.location.hostname + window.location.pathname + "/progress.json', function(data){ 
	 
		var items = []; 
		value = 0; 
		
        if(data){ 
        	var total = data['total']; 
        	var current = data['current'];  
        	var value = Math.floor((current / total) * 100);  
  
        	if(value>0){ 
        		
        		var str = value.toString();
        		str = str.concat("%");
        		
        		$(".progress-bar").attr("aria-valuenow", value);
    			$(".progress-bar").css("width", str);
    			$(".progress-bar").text(str);
        	}  
        } 
        
        if(value < 100){  
        	t = setTimeout("updateStatus()", 500);  
        }
        
	});
  
}


