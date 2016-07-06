

<div id="wrapper">

	<!--  <div class="top fixed"><p> Identity: </p></div> -->
		
	<div class="col-md-12">
	    <div class="row">
	        <div class="col-sm-2 side fixed">
	        	<div class="show-identity">
		        	<?php 
		        		$data['identity'] = $identity;
		        		$this->load->view('pages/identity', $data);
		        	?>
	        	</div>
		    	<select class="form-control selector">
			    	<?php 
		        		foreach ($classes as $class) {	
		        	?>	        			
		       			<option data-label="<?=$class->label?>"><?=str_replace("_", " ", $class->name)?></option>
		        	<?php
		        		}
		        	?>
		       	</select>
		       	<div class="export">
		       		<button type="button" class="btn btn-primary btn-export" data-toggle="modal" data-target="#export-modal" data-backdrop="static" data-keyboard="false">
		       			Export dataset
		       		</button>
		    	</div>
	        </div>
		    <div class="col-sm-10 scroll">
		    	<div class="show-gallery">
				    <?php 			    
					    $data['identity'] = $identity;
					    $data['gallery'] = $gallery;
					    $data['offset'] = $offset;
					    $this->load->view('pages/gallery', $data);		
				    ?>
			    </div>
			    <div class="np-button">
			    	<div>
    					<button type="button" data-offset=<?=$offset?> class="btn btn-primary btn-next">Next</button>
    					<button type="button" data-offset=<?=$offset?> class="btn btn-primary btn-prev">Prev</button>
    				</div>
    			</div>
			</div>
	    </div>
	</div>
	
	<?php $this->load->view('pages/modal'); ?>
        
</div>