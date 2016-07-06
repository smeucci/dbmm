<?php

class Gallery_model extends CI_Model {
	
	function __construct(){
		parent::__construct();
		$this->load->database();
	}
	
	public function get_identities_list () {
		
		$query = $this->db->query("	SELECT label, name
									FROM identities");
		
		$array = array();
		foreach ($query->result() as $key => $res) {
			$data = new stdClass();
			$data->label = $res->label;
			$data->name = $res->name;
			$array[$key] = $data;
		}
		
		return $array;
		
	}
	
	public function get_default_identity () {
			
		$query = $this->db->query("	SELECT *
									FROM identities
									LIMIT 1");
	
		$result = $query->result();
		
		$data = new stdClass();
		$data->label = $result[0]->label;
		$data->name = $result[0]->name;
		$data->num_images = $result[0]->num_images;
		$data->remove = $result[0]->remove;
		$data->avatar = $this->get_default_image ($data->label);
		
		return $data;
				
	}
	
	public function get_identity ($label) {
		
		$query = $this->db->query("	SELECT *
									FROM identities 
									WHERE label = '".$label."'");
		
		$result = $query->result();
		
		$data = new stdClass();
		$data->label = $result[0]->label;
		$data->name = $result[0]->name;
		$data->num_images = $result[0]->num_images;
		$data->remove = $result[0]->remove;
		$data->avatar = $this->get_default_image ($data->label);
		
		return $data;
	}
	
	public function get_default_image ($identity_label) {
		
		$query = $this->db->query("	SELECT image
									FROM images_crop
									WHERE identity = '".$identity_label."'
									LIMIT 1");
		
		$result = $query->result();
		
		$data = $result[0]->image;
		
		return $data;
		
	}
	
	public function get_gallery_images ($identity_label, $num, $offset) {
		
		$query = $this->db->query("	SELECT *
									FROM images_crop
									WHERE identity = '".$identity_label."'
									LIMIT ".$num."
									OFFSET ".$offset."");
		
		$data = new stdClass();
		$data->gallery = $query->result();
		$data->offset = $offset;
		
		return $data;
		
	}
	
	public function validate_image ($image, $identity_label, $old_image, $box, $validation) {
		
		$data = array('validation' => $validation);
		$where = array('image' => $image, 'identity' => $identity_label);
		
		$this->db->where($where);
		$this->db->update('images_crop', $data);
		
		$where = array('image' => $old_image, 'identity' => $identity_label, 'box' => $box);
		$this->db->where($where);
		$this->db->update('images', $data);
		
	}
	
	public function remove_identity ($label, $remove) {
		
		$data = array('remove' => $remove);
		$where = array('label' => $label);
		
		$this->db->where($where);
		$this->db->update('identities', $data);
		
	}
	
	public function export_database_sql ($tables, $where_clauses) {
		
		if (!file_exists('export')) {
			mkdir('export', 0777, true);
		}
		
		//cycle through
		foreach($tables as $key=>$table) {
			
			$query = $this->db->query("SELECT * FROM  ".$table." ".$where_clauses[$key]);
			$result = $query->result();
			$fields = $this->db->list_fields($table);
			$num_fields = sizeof($fields);
			
			// $return.= 'DROP TABLE '.$table.';';
			$query = $this->db->query("SHOW CREATE TABLE ".$table);
			$result2 = $query->result();
			$return.= "\n\n".$result2[0]->{'Create Table'}.";\n\n";
			
			$return.= "INSERT INTO ".$table." ( ";
			for ($i = 0; $i < $num_fields; $i++) {
				$return .= $fields[$i];
				if ($i + 1 < $num_fields) {
					$return .= " , ";
				}
			}
			
			$return .= ") VALUES\n";
			$tot_result = sizeof($result);
			
			foreach ($result as $key=>$row) {
				
				$return .= "( ";
				
				for ($j = 0; $j < $num_fields; $j++) {
					
					$data = $row->$fields[$j];
					
					if ($data == null) { 
						$data = 'NULL'; 
					} else {
						$data = "'".$data."'";
					}
					
					$return .= $data;
					
					if ($j + 1 < $num_fields) { $return .= " , "; }
				}
				
				$return .= ")";

				if ($key + 1 < $tot_result) { $return .= ",\n"; }
			}
			
			$return .= ";\n\n";
			
			$return .= "\n#####################################################################\n";
						
		}
		
		$return = str_replace("TABLE", "TABLE IF NOT EXISTS", $return);
		
		// save file
		$filename = 'export/export-'.date('d-m-Y').'.sql';
		$handle = fopen($filename,'w+');
		fwrite($handle,$return);
		fclose($handle);

	}
	
	public function export_database_csv ($tables, $where_clause) {
		
		if (!file_exists('export')) {
			mkdir('export', 0777, true);
		}
		
		//cycle through
		foreach($tables as $key=>$table) {
			
			$return = "";
				
			$query = $this->db->query("SELECT * FROM  ".$table." ".$where_clauses[$key]);
			$result = $query->result();
			$fields = $this->db->list_fields($table);
			$num_fields = sizeof($fields);
			
			for ($i = 0; $i < $num_fields; $i++) {
				$return .= '"'.$fields[$i].'"';
				if ($i + 1 < $num_fields) {
					$return .= ",";
				} else {
					$return .= "\n";
				}
			}
				
			$tot_result = sizeof($result);
				
			foreach ($result as $key=>$row) {
				
				for ($j = 0; $j < $num_fields; $j++) {
						
					$data = $row->$fields[$j];
						
					if ($data == null) {
						$data = 'NULL';
					} else {
						$data = "'".$data."'";
					}
						
					$return .= '"'.$data.'"';
						
					if ($j + 1 < $num_fields) { $return .= ","; }
				}
						
				if ($key + 1 < $tot_result) { $return .= "\n"; }
			}
			
			// save file
			$filename = 'export/export-'.$table."-".date('d-m-Y').'.csv';
			$handle = fopen($filename,'w+');
			fwrite($handle,$return);
			fclose($handle);
			
		}
		
	}
	
	public function export_dataset ($where_clauses, $table = "images_crop") {
		
		$data_path = $this->config->config['data_path'];
		
		$export_path = $data_path.'img_export/';
		if (strcmp($table, 'images') == 0) { $image_path = $data_path.'img/'; }
		else if (strcmp($table, 'images_crop') == 0) { $image_path = $data_path.'img_crop/'; }
		
		if (!file_exists($export_path)) {
			mkdir($export_path, 0777, true);
		}
		
		$f = fopen('progress.json', "w");
		$progress = new stdClass();
		$progress->total = 0;
		$progress->current = 0;	
		fwrite($f, utf8_encode(json_encode($progress)));
		fclose($f);
		
		$query = $this->db->query("SELECT * FROM identities WHERE remove is NULL");
		$identities = $query->result();
		
		$progress->total = sizeof($identities);
		
		foreach ($identities as $key => $identity) {
			
			$folder = $identity->label."_".$identity->name."/";
			if (!file_exists($export_path.$folder)) {
				mkdir($export_path.$folder, 0777, true);
			}
			
			$query = $this->db->query("SELECT * FROM ".$table." WHERE identity = '".$identity->label."' 
									   AND ((predicted = 1 AND validation is NULL) 
									   OR (predicted = 1 AND validation = 1) 
									   OR (predicted = 0 AND validation = 1))");
			$images = $query->result();
			
			foreach ($images as $image) {
				
				$label = $identity->label;
				$name = $identity->name;
				$img = $image->image;
				
				
				$path = $folder.$img;
				
				$source = $image_path.$path;
				$dest = $export_path.$path;
				
				copy($source, $dest);
				
			}
			
			$progress->current = $key + 1;
			
			$f = fopen('progress.json', "w");
			fwrite($f, utf8_encode(json_encode($progress)));
			fclose($f);
			
		}
		
	}
	
	
	
}
