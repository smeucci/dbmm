

<div class="centered welcome">
	<div class="jumbotron">
		<p class="title">Visual Validation</p>
				
		<p  class="description">
		This tool has the purpose of visually validate the results of an image classification in order to improve the purity of the automatically collected and
		annotated dataset and subsequently export the dataset.
		For each identity, that corresponds to a class and for which a reference image is shown in the top left, a classifier was trained in order 
		to remove images that do not belong to that class.
		An image shown in a <font color='red'>RED</font> box represents an image that the classifier identifies as NOT belonging to that class.
		</p>
		
		<p  class="description">
		Use this tool to validate the results of these classifiers across all identities.
		An image is either classified as belonging to that class (no box) or not belonging to that class (<font color='red'>RED</font> box). 
		To change this property, double-click on an image.
		</p>
		
		<p class="description">
		An identity can also be "remove" from the dataset. An identity with the reference image shown in a <font color='red'>RED</font> box is "remove" by the dataset, meaning
		it will not be considered for the export operation.
		To change whether or not an identity is to be removed, double click on the reference image.
		</p>
		
		<p  class="description">
		Use the "next" and "prev" buttons to navigate through the images of an identity.
		Use the select box to change the identity shown.
		</p>
		
		<button type="button" class="btn btn-primary btn-lg start">Start</button>
	</div>
</div>