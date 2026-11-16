class_name ArcadeThemes
extends RefCounted

const NAMES_ZH := ["鸡舍","羊圈","松鼠区","菜园"]
const NAMES_EN := ["Coop","Sheepfold","Squirrel Yard","Garden"]
const ITEMS_ZH := ["鸡蛋","羊毛","松果","包菜"]
const ITEMS_EN := ["Eggs","Wool","Cones","Cabbages"]
const ANIMALS_ZH := ["母鸡","绵羊","松鼠","小狗"]

static func name_for(index: int, language := "zh") -> String:
	return (NAMES_EN if language == "en" else NAMES_ZH)[index-1]

static func item_for(index: int, language := "zh") -> String:
	return (ITEMS_EN if language == "en" else ITEMS_ZH)[index-1]
