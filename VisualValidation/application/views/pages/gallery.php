
<?php 

	foreach ($gallery as $image) {     
		$str = "media/".$identity->label."_".$identity->name."/".$image->image;
		
		if ($image->predicted == 1 && $image->validation == null) {
			$lbl = 1;
		} else if ($image->predicted == 1 && $image->validation == 1) {
			$lbl = 1;
		} else if ($image->predicted == 1 && $image->validation == 0) {
			$lbl = 0;
		} else if ($image->predicted == 0 && $image->validation == 1) {
			$lbl = 1;
		} else if ($image->predicted == 0 && $image->validation == null) {
			$lbl = 0;
		} else if ($image->predicted == 0 && $image->validation == 0) {
			$lbl = 0;
		}		
		
?>

		<div  class="col-lg-2 col-md-4 col-xs-6 thumb gall">
			<a class="thumbnail gallery lbl-<?= $lbl ?>" data-img="<?= $image->image ?>" data-old="<?= $image->old_image ?>" data-box="<?= $image->box ?>">
				<img src="<?=$str?>" style="height:120px; width:120px;">
			</a>
		</div>
		
<?php  
	}
?>

     	
    	   	