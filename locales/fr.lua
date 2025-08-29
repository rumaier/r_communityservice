Language = Language or {}
Language['fr'] = { -- French

    -- Notifications
    noti_title = 'Service Communautaire',
    restricted_area = 'Vous ne pouvez pas entrer dans cette zone.',
    no_access = 'Vous n\'êtes pas autorisé à faire cela.',
    no_self_assign = 'Vous ne pouvez pas vous assigner un service communautaire.',
    player_not_found = 'Joueur ID %s introuvable.',
    assigned_comms = 'Vous avez assigné %s tâches de service communautaire à %s.',
    received_comms = 'On vous a assigné %s tâches de service communautaire.',
    finish_comms = 'Vous devez terminer votre service communautaire avant de quitter la zone.',
    task_complete = 'Tâche terminée! %s tâches restantes.',
    comms_complete = 'Vous avez terminé votre service communautaire. Vous êtes libre de partir!',

    -- UI Elements
    command_help = 'Ouvrir le menu du service communautaire',
    menu_title = 'Service Communautaire',
    give_comms = 'Assigner Service Communautaire',
    give_comms_desc = 'Assigner des tâches de service communautaire à un joueur',
    manage_comms = 'Gérer Service Communautaire',
    manage_comms_desc = 'Voir et retirer les joueurs du service communautaire',
    remove_comms = 'Retirer Service Communautaire',
    remove_comms_content = 'Êtes-vous sûr de vouloir retirer ce joueur du service communautaire?',
    admins_only = 'Cette option est réservée aux administrateurs.',
    task_amount = 'Nombre de Tâches',
    click_to_remove = 'Cliquer pour retirer',
    task_help = 'Allez à l\'endroit marqué et creusez le trou.',
    dig_here = '[E] - Creuser Ici',
    dig_progress = 'Creusage...',
    refresh = 'Actualiser',
    go_back = 'Retour',

    -- Webhook
    comms_assigned = 'Service Communautaire Assigné',
    comms_removed = 'Service Communautaire Retiré',
    comms_completed = 'Service Communautaire Terminé',
    
    player_id = 'ID du Joueur',
    username = 'Nom d\'Utilisateur',
    identifier = 'Identifiant',
    assigner_id = 'ID de l\'Assigneur',
    tasks_assigned = 'Tâches Assignées',
    remover_id = 'ID du Retireur',

    -- Console
    resource_version = '%s | v%s',
    bridge_detected = '^2Bridge détecté et chargé.^0',
    bridge_not_detected = '^1Bridge non détecté, assurez-vous qu\'il fonctionne.^0',
    cheater_print = 'Vous avez essayé de duper le système. Le système vous a dupé.',
    debug_enabled = '^1Le mode debug est ACTIVÉ! N\'exécutez PAS ceci en production!^0',
}