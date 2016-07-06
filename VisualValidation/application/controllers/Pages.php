<?php

class Pages extends CI_Controller {
	
	function __construct(){
		parent::__construct();
		$this->load->model('Gallery_model');
	}
	
	public function index ($page = 'welcome') {
		
		error_reporting(0);
		
		if ( ! file_exists(APPPATH.'/views/pages/'.$page.'.php'))
		{
			// Whoops, we don't have a page for that!
			show_404();
		}
		
		$this->load->helper('url');
		$this->load->view('templates/header', $data);
		$this->load->view('pages/'.$page, $data);
		$this->load->view('templates/footer', $data);
		
	}

	public function home () {
		
		$num = $_POST['num'];
		
		$data['classes'] = $this->Gallery_model->get_identities_list();			
		$data['identity'] = $this->Gallery_model->get_default_identity();
		
		$gallery = $this->Gallery_model->get_gallery_images($data['identity']->label, $num, 0);
		$data['gallery'] = $gallery->gallery;
		$data['offset'] = $gallery->offset;
		
		echo $this->load->view('pages/home', $data, true);
				
	}
	
	public function get_identity_ajax () {
		
		$num = $_POST['num'];
		
		$res = new stdClass();
		
		$data['identity'] = $this->Gallery_model->get_identity($_POST['label']);
		
		$res->identity_div = $this->load->view('pages/identity', $data, true);
		
		$gallery = $this->Gallery_model->get_gallery_images($data['identity']->label, $num, 0);
		$data['gallery'] = $gallery->gallery;
		$data['offset'] = $gallery->offset;
		
		$res->gallery = $this->load->view('pages/gallery', $data, true);
		
		echo json_encode($res);
		
	}
	
	public function get_gallery_images_ajax () {
	
		$identity_label = $_POST['label'];
		$identity_name = $_POST['name'];
		$num = $_POST['num'];
		$offset = $_POST['offset'];
		
		$gallery = $this->Gallery_model->get_gallery_images($identity_label, $num, $offset);
		
		$data['identity'] = new stdClass();
		$data['identity']->label = $identity_label;
		$data['identity']->name = $identity_name;
		$data['gallery'] = $gallery->gallery;
		$data['offset'] = $gallery->offset;
		
		$res = new stdClass();
		$res->html = $this->load->view('pages/gallery', $data, true);
		$res->count = count($data['gallery']);
		
		echo json_encode($res);
		
	}
	
	public function validate_image_ajax () {
		
		$image = $_POST['image'];
		$identity_label = $_POST['label']; 
		$old_image = $_POST['old_image'];
		$box = $_POST['box'];
		$validation = $_POST['validation'];
		
		$this->Gallery_model->validate_image($image, $identity_label, $old_image, $box, $validation);
		
	}
	
	public function remove_identity_ajax () {
		
		$label = $_POST['label'];
		$remove = $_POST['remove'];
		
		if ($remove == 0) {
			$remove = null;
		}
		
		$this->Gallery_model->remove_identity($label, $remove);
		
		
	}
	
	
	public function export_ajax () {
		
		$tables = array("identities", "images", "images_crop");
		$where_clauses  = array(
				
				"WHERE remove is NULL",
				
				"WHERE identity not in (select label from identities where remove is not NULL) 
				AND ((predicted = 1 AND validation is NULL) 
				OR (predicted = 1 AND validation = 1) 
				OR (predicted = 0 AND validation = 1))",
				
				"WHERE identity not in (select label from identities where remove is not NULL) 
				AND ((predicted = 1 AND validation is NULL) 
				OR (predicted = 1 AND validation = 1) 
				OR (predicted = 0 AND validation = 1))"
				
		);
		
		$this->Gallery_model->export_dataset($where_clauses);
		$this->Gallery_model->export_database_csv($tables, $where_clauses);
		$this->Gallery_model->export_database_sql($tables, $where_clauses);
		
	}
	
	
	
	
}
