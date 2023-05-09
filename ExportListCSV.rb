#SKETCHUP_CONSOLE.clear()																		#Pour nettoyer la console
require 'csv'																				#Import les fonctions CSV

def analyze(entity)
  
	entityLayerName = entity.layer.name
	
	#On check l'entitée et on traite les données si possible	
	if entityLayerName != "Layer0" && $visible_layers.include?(entityLayerName)				#Si le calque n'est pas Layer0, on regarde si le calque est visible
		case $exportType
		when 1																				#Si $exportType vaut 1, on inclue la localité dans l'export							
			ligne = [entityLayerName,entity.definition.name.split("#").first,entity.name.split("#").first,entity.parent.name]	#On insère les données dans une ligne
		when 2																				#Si $exportType vaut 2, on n'inclue pas la localité dans l'export
			ligne = [entityLayerName,entity.definition.name.split("#").first,entity.name.split("#").first]						#On insère les données dans une ligne
		end
		
		$definitionsInfos << ligne															#On insère la ligne dans un tableau

	end
  
	#Si il y'a des entitées nestead, on check l'intérieur
	entity.definition.entities.each{|subentity|												#Pour chaque entity trouvée, on créé un objet subentity
		isGroupOrComponentAnalyse(subentity)												#On regarde si c'est un groupe ou composant et analyse
	}

end

def isVisibleLayerFolder(layerFolder, layerName)
	if layerFolder.visible?																	#Regarde si le dossier de balise est visible
		if layerFolder.folder																#Regarde si il y'a un dossier de balise dans le dossier de balise
			layerFolder = layerFolder.folder												#Créé une variable avec le dossier de balise en cours d'analyse
			isVisibleLayerFolder(layerFolder, layerName)									#Appelle la fonction d'analyse de dossier de layer et passe en argument le nom du dossier et de la balise	
		else
			$visible_layers<< layerName														#Si il n'y a plus de dossier de balise et que celuici est visible, alors le calque est visible, on insert dans la liste
		end
	end																						#Si le dossier de balise n'est pas visible, on arrête de chercher
end

def prepareExportCSV()

	$definitionsInfos = []																	#On créé une variable pour stocker les infos des definitions (s = array)
	$readyToExport = []																		#On créé un tableau dans lequel on stockera les infos à exporter
	$csvEntete = []																			#On créé un tableau qui stockera l'entete du fichier csv

	model = Sketchup.active_model															#Raccourcis vers le model
	
	#liste les calques visible
	$visible_layers = []																	#On créé une variable pour stocker les calques visibles
	model.layers.each { |layer| 															#Pour chacun des layers
		if layer.visible?																	#Si le layer est visible
			layerName = layer.name															#Créé une variable avec le nom du layer en cours d'analyse
			if layer.folder																	#On regade si il est dans un dossier de layer
				layerFolder = layer.folder													#Créé une variable avec le dossier de balise en cours d'analyse
				isVisibleLayerFolder(layerFolder, layerName) 								# Appelle la fonction d'analyse de dossier de layer et passe en argument le nom du dossier et de la balise		
			else
				$visible_layers<< layerName													# On stock le nom dans la liste des layer visibles
			end
		end
		}
	
	#On regade chaque entiées
	entities = model.active_entities														# On récupère toutes les entities dans le model
	entities.each{ |entity|  																# Pour chaque entity trouvée, on créé un objet Entity
		isGroupOrComponentAnalyse(entity)													# On regarde si c'est un groupe ou composant et analyse
	}
	
	entityBilan()																			# Fait le décompte de chaque éléments

	#On génère le CSV
	CSV.open("donnees.csv", "wb") do |csv|													# Création du fichier CSV
		csv << $csvEntete																	# Insertion de l'entête de colonnes
		$readyToExport.each do |ligne|														# On récupère chaque entrée de definitionsInfos
			csv << ligne																	# On insère chaque ligne dans le fichier csv
		end
	end 																					# Ferme CSV automatiquement
 
	#on ouvre le fichier csv
	pid = spawn('notepad.exe donnees.csv')													# Permet l'ouverture du fichier créé
	Process.detach(pid)																		# Détache la commande du programme pour que Sketchup n'attende pas la fermeture du notrepad.

end

def isGroupOrComponentAnalyse(subentity)													# Fonction pour savoir si l'entity est un groupe ou composant, et lancer l'analyse si c'est un groupe ou composant

	if subentity.is_a?(Sketchup::ComponentInstance) || subentity.is_a?(Sketchup::Group)		# On cherche à savoir si subentity est un groupe ou un composant
		analyze(subentity)																	# Si oui, on analyze
	end

end

def entityBilan()
  
	qt_sums = Hash.new(0)																	# créer un hash pour stocker les sommes par ligne identique
  
	$definitionsInfos.each do |ligne| 														# parcourir chaque ligne dans le tableau   
		qt_sums[ligne] += 1																	# ajouter la quantité de l'entité à la somme correspondante dans le hash
	end
  
	$definitionsInfosRecap = [] 															# créer un nouveau tableau avec les quantités sommées
	$definitionsInfos.each do |ligne|
		ligneRecap = ligne.dup << qt_sums[ligne]  											# ajouter la somme de quantités à la fin de chaque ligne  
		$definitionsInfosRecap << ligneRecap 												# ajouter la ligne modifiée au nouveau tableau
	end

	$readyToExport = $definitionsInfosRecap.uniq											# Supprime les lignes doublons

end

def exportBilanLocation()																	

	$exportType = 1
	$csvEntete = ["Layer","Type","Nom","Localitée","QT"]									#L'entête du CSV prend en compte la localité
	prepareExportCSV()
	
end

def exportBilanGlobal()

	$exportType = 2
	$csvEntete = ["Layer","Type","Nom","QT"]												#L'entête du CSV ne prend pas en compte la localité
	prepareExportCSV()
	
end

################################
## Creation du menu ############
################################
if( not file_loaded?("exportListCSV.rb") )													# Si le fichier n'est pas déjà chargé
	tool_menu = UI.menu("Plugins")															# on va dans le menu Plugins
	menuCSV = tool_menu.add_submenu("Exports CSV")											# on ajoute un sous menu
	menuCSV.add_item("Export Donnée Localisée") { exportBilanLocation }						# on créé un menu Export CSV qui lance la fonction exportCSV
	menuCSV.add_item("Export Donnée Global") { exportBilanGlobal }	 						# on créé un menu Export CSV qui lance la fonction exportCSV
	file_loaded("exportListCSV.rb")															# on indique que est chargé
end




#https://forums.sketchup.com/t/get-a-list-with-all-the-components-in-component-browser/212896/4

#https://forums.sketchup.com/t/count-and-manipulate-groups-nested-in-a-component/150984
#all_used_compos = model.definitions.find_all{|d| !d.group? && !d.image? && d.instances[0] } 


# https://forums.sketchup.com/t/how-to-get-all-entities-with-the-specific-tag/192624/3
# next unless entity.layer == @active_layer

          # @tag_entities << entity
