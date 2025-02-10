# Trident Survival V5 ESP Script (v5.2)

import clr
# Import .NET Common Language Runtime
clr.AddReference('System.Windows.Forms')
# Enable winforms for easy GUI setup
import System.Windows.Forms
from System.Windows.Forms import Form, Button
import System.Drawing

# Initializing
form = Form(Width=400, Height=200)
button = Button(Text="ESP Settings", Width=100, Height=30, Top=10, Left=10)
checkboxEsp = System.Windows.Forms.CheckBox()
checkboxEsp.Text = "ESP?"
checkboxEsp.Location = System.Drawing.Point(15, 45)
checkboxEsp.AutoSize = True
checkboxEsp.CheckState = System.Windows.Forms.CheckState.Checked
textListSpacing = System.Windows.Forms.TextBox()
textListSpacing.Text = "10"
textListSpacing.Location = System.Drawing.Point(15, 75)
textListSpacing.Width = 100
textListSpacing.Height = 30

# ESP Settings
def espSettings():
    global espVisible, listSpacing
    if checkboxEsp.Checked:
        espVisible = True
        listSpacing = 10
    else:
        espVisible = False

# Load Window
form.Controls.Add(button)
form.Controls.Add(checkboxEsp)
form.Controls.Add(textListSpacing)
button.Click += lambda s, e: espSettings()
form.ShowDialog()
import clr
from mca import Minecraft

# Load the Minecraft class from Minecraft Assembly
clr.AddReference('MinecraftAssembly')
from mca import Minecraft
from TridentSurvivalV5Class import game
from TridentSurvivalV5Class import character

# Create a new Minecraft instance
mc = Minecraft()

def onTick(game):
    global espVisible, listSpacing
    if espVisible:
        # Use player position and get surrounding players
        x, y, z = mc.player.position
        players = mc.players.getSurnoundingPosition(x, y, z, listSpacing)
        # Draw ESP around them
        for player in players:
            mc.drawCircle(position=player.position, radius=2.5)
    else:
        # Clean up circles
        mc.drawClearCircles()

# Register the onTick fuction as a callback
game.onTick += onTick
character.onAttack += onTick
