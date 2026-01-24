"""Utilitaires pour les IDs formatés"""

def extract_id(formatted_id):
    """
    Convertit un ID formaté (AG-001, CL-002) ou simple (1, 2) en integer
    
    Exemples:
    - "AG-001" -> 1
    - "CL-002" -> 2
    - "1" -> 1
    - 1 -> 1
    """
    if isinstance(formatted_id, int):
        return formatted_id
    
    if isinstance(formatted_id, str):
        # Si c'est un texte formaté (AG-001, CL-002, etc.)
        if '-' in formatted_id:
            # Prendre la partie après le tiret
            try:
                return int(formatted_id.split('-')[1])
            except (IndexError, ValueError):
                raise ValueError(f"Format d'ID invalide: {formatted_id}")
        else:
            # Sinon c'est juste un nombre
            try:
                return int(formatted_id)
            except ValueError:
                raise ValueError(f"Impossible de convertir {formatted_id} en entier")
    
    raise ValueError(f"Type d'ID invalide: {type(formatted_id)}")


def format_agent_id(agent_id):
    """Formate un ID agent: 1 -> AG-001"""
    return f"AG-{int(agent_id):03d}"


def format_client_id(client_id):
    """Formate un ID client: 1 -> CL-001"""
    return f"CL-{int(client_id):03d}"


def format_ids(data_dict):
    """Remplace les IDs numériques par des IDs formatés dans un dictionnaire"""
    if 'agent_id' in data_dict and data_dict['agent_id']:
        data_dict['agent_id_formatted'] = format_agent_id(data_dict['agent_id'])
    if 'client_id' in data_dict and data_dict['client_id']:
        data_dict['client_id_formatted'] = format_client_id(data_dict['client_id'])
    return data_dict
