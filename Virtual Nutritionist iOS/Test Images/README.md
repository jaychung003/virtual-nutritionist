# Test Menu Images

This folder contains sample restaurant menu images for testing the Virtual Nutritionist app in the iOS Simulator.

## Available Test Images

### 1. cache_brunch_menu.jpg
**Restaurant:** Caché (San Francisco)
**Menu Type:** Lunch/Brunch

**Test Coverage:**
- **Shellfish:** Oysters X6, Mussels marinière, Octopus hot dog
- **Gluten:** Bread, toast, Croque Monsieur
- **Gluten-free options:** Buckwheat crepes (naturally GF)
- **Dairy:** Cheese, butter, cream sauce, ice cream
- **Eggs:** Eggs Benedict (3 variations), poached eggs
- **Meat:** Bacon, ham, chorizo, duck confit, hanger steak
- **Fish:** Smoked salmon (in multiple dishes)
- **Nuts/Peanuts:** Pistachio crème brûlée, Profiterole with peanuts
- **Hidden allergens:**
  - Mortadella (traditionally contains pistachios)
  - Satay potato (typically contains peanut sauce)

**Good for testing these protocols:**
- ✅ Vegan (21/24 items should be flagged)
- ✅ Vegetarian
- ✅ Gluten-free
- ✅ Dairy-free
- ✅ Egg-free
- ✅ Shellfish-free
- ✅ Fish-free
- ✅ Nut-free
- ✅ Peanut-free
- ✅ Red meat-free
- ✅ Pork-free

## How to Use in iOS Simulator

### Option 1: Drag & Drop
1. Open the iOS Simulator
2. Drag `cache_brunch_menu.jpg` directly onto the simulator window
3. The image will be saved to the simulator's Photos app
4. Open your app and select the image from Photos

### Option 2: Command Line
```bash
# Add image to simulator's photo library
xcrun simctl addmedia booted "/Users/jaychung/Virtual Nutritionist/Virtual Nutritionist iOS/Test Images/cache_brunch_menu.jpg"
```

### Option 3: Finder
1. Open this folder in Finder:
   ```bash
   open "/Users/jaychung/Virtual Nutritionist/Virtual Nutritionist iOS/Test Images"
   ```
2. Drag the image to your simulator

## Expected Results

When testing `cache_brunch_menu.jpg` with **vegan** protocol:
- **21 items** should be flagged as "AVOID"
- **3 items** should be "CAUTION" (salads)
- **0 items** should be "SAFE"

When testing with **gluten_free + shellfish_free** protocols:
- **7 items** should be "SAFE" (buckwheat crepes)
- **8 items** should be "CAUTION"
- **9 items** should be "AVOID"

## Adding More Test Images

To add more test menu images:
1. Save menu photos to this folder
2. Use descriptive names: `{restaurant}_{menu_type}.jpg`
3. Update this README with test coverage details
