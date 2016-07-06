
<?php 
	if ($identity->remove == 1) {
		$rmv = 1;
	} else {
		$rmv = 0;
	}

?>

<div class="identity-div" data-label="<?=$identity->label?>" data-name="<?=$identity->name?>">
	<a class="identity-img rmv-<?= $rmv ?>">
		<img src="media/<?= $identity->label ?>_<?= $identity->name ?>/<?= $identity->avatar ?>">
	</a>
	<div class="identity-info">
		<p> Label: <?= $identity->label?></p>
		<p> Name: <?= str_replace("_", " ", $identity->name) ?></p>
	</div>
</div>

