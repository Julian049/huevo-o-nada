with open('scenes/world/main.tscn', 'r', encoding='utf-8') as f:
    text = f.read()
start = text.find('[node name=\"UIManager\"')
end = text.find('[node name=\"HenManager\"')
print(text[start:end])
