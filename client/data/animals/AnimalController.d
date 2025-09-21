{
"$schema": "https://json-schema.org/draft/2020-12/schema",
"$id": "https://awa/schemas/quest.json",
"type": "object",
"required": ["id","title","steps","rewards"],
"properties": {
"id": {"type": "string"},
"title": {"type": "string"},
"steps": {"type": "array", "items": {"type": "string"}},
"rewards": {"type": "array", "items": {"enum": ["unlock_animal","unlock_pattern","unlock_emote","materials"]}}
}
}