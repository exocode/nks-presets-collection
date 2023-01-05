# Xfer Record Serum
#
# notes
#  - Komplete Kontrol 1.5.0(R3065)
#  - Serum  1.073 Oct 5 2015
# ---------------------------------------------------------------
path        = require 'path'
gulp        = require 'gulp'
tap         = require 'gulp-tap'
data        = require 'gulp-data'
gzip        = require 'gulp-gzip'
rename      = require 'gulp-rename'
sqlite3     = require 'sqlite3'
util        = require '../lib/util'
commonTasks = require '../lib/common-tasks'
nksfBuilder = require '../lib/nksf-builder'
adgExporter = require '../lib/adg-preset-exporter'
bwExporter  = require '../lib/bwpreset-exporter'
appcGenerator = require '../lib/appc-generator'

# buld environment & misc settings
#-------------------------------------------
$ = Object.assign {}, (require '../config'),
  prefix: path.basename __filename, '.coffee'
  
  #  common settings
  # -------------------------
  dir: 'Serum'
  vendor: 'Xfer Records'
  magic: 'XfsX'
  
  #  local settings
  # -------------------------
  # serum factory prestes folder
  serumPresets: '/Library/Audio/Presets/Xfer Records/Serum Presets/Presets'
  # Ableton Live 10.0.1
  abletonRackTemplate: 'src/Serum/templates/Serum.adg.tpl'
  # Bitwig Studio 1.3.14 RC1 preset file
  bwpresetTemplate: 'src/Serum/templates/Serum.bwpreset'
  db: '/Library/Audio/Presets/Xfer\ Records/Serum\ Presets/System/presetdb.dat'
  query: '''
select
  PresetDisplayName
  ,PresetRelativePath
  ,Author
  ,Description
  ,Category
from
  SerumPresetTable
where
  PresetDisplayName = $name
  and PresetRelativePath = $folder
'''

# regist common gulp tasks
# --------------------------------
commonTasks $

# preparing tasks
# --------------------------------

# Here you can add search strings for automatic category mapping. This is useful if the preset creator didn't add the category tag to it and only encoded the type of the sound within the naming.
# eg: "BS - Ultimate Bass.fxp" -> Bass
#     "PLCK - Some Noise.fxp"  -> Pluck

# keep in mind that the first match will be taken.

categoryMap = {
  "Synth": ["SY","Syn","Synth"],
  "Bass": ["BS","Bass"]
  "Lead": ["LD","lead", "Saw", "Template"],
  "Sequence": ["SQ","Seq"],
  "Stab": ["STB","Stab"],
  "SFX": ["SFX","FX", "Effect"],
  "Keyboard": ["KEY","Key"],
  "Pluck": ["PL","PLCK", "PLK", "Pluck"],
  "Pad": ["Pad","PD"],
  "Drum": ["808", "909", "Kick", "Drum"],
  "String": ["String"],
  "Organ": ["ORGAN"]
  "Arpeggio": ["ARP","Arpeggio", "AR"],
  "Chord": ["CH","CHRD", "CHD", "Chord"],
}

# search at the beginning of a string
startMatch = (str, map) ->
  # Convert the input string to lowercase
  str = str.toLowerCase()

  # Create a new map object with lowercase values
  lowerCaseMap = {}
  for key, value of map
    lowerCaseMap[key] = value.map((val) -> val.toLowerCase())

  for key, value of lowerCaseMap
    for val in value
      if str.startsWith(val)
        return key
  return null

# search within the name
containMatch = (str, map) ->
  # Convert the input string to lowercase
  str = str.toLowerCase()

  # Create a new map object with lowercase values
  lowerCaseMap = {}
  for key, value of map
    lowerCaseMap[key] = value.map((val) -> val.toLowerCase())

  for key, value of lowerCaseMap
    for val in value
      if str.includes(val)
        return key
  return null


# generate metadata
gulp.task "#{$.prefix}-generate-meta", ->
  # open database
  db = new sqlite3.Database $.db, sqlite3.OPEN_READONLY
  gulp.src ["#{$.serumPresets}/**/*.fxp"]
    .pipe data (file, done) ->
      console.info path.dirname file.relative
      # SQL bind parameters
      params =
        $name: path.basename file.path, '.fxp'
        $folder: path.dirname file.relative
      # execute query

      console.log "params: " + JSON.stringify(params)
      db.get $.query, params, (err, row) ->

        console.log "row: " + JSON.stringify(row)
        # console.log "row.Category: " + row?.Category

        searchName = row?.PresetDisplayName?.trim() ||  path.basename(file.path, '.fxp')
        console.log "searchName: " + searchName
        result = startMatch(searchName, categoryMap) || containMatch(searchName, categoryMap)
        console.log "Looking for: " + row?.PresetDisplayName?.trim()
        console.log "row.Category? " + row?.Category?.trim()
        console.log "RESULT : " + result
        # return if row == undefined

        chain = if file.path.startsWith "/Library/Audio/Presets/Xfer Records/Serum Presets/Presets/User/" then "User" else 'Serum Factory'
        console.log "chain: " + file.path

        done err,
          vendor: $.vendor
          types: [[row?.Category?.trim() || result]]
          name: searchName
          deviceType: 'INST'
          comment: row?.Description?.trim()
          bankchain: ['Serum', chain, '']
          author: row?.Author?.trim()
    .pipe tap (file) ->
      file.data.uuid = util.uuid file
      file.contents = Buffer.from util.beautify file.data, on
    .pipe rename
      extname: '.meta'
    .pipe gulp.dest "src/#{$.dir}/presets"
    .on 'end', ->
      # colse database
      db.close()

#
# build
# --------------------------------

# build .nksf files to dist folder
gulp.task "#{$.prefix}-dist-presets", ->
  builder = nksfBuilder $.magic, "src/#{$.dir}/mappings/default.json"
  gulp.src ["#{$.serumPresets}/**/*.fxp"], read: on
    .pipe data (file) ->
      # fxp header 60 byte - PCHK header 4 byte
      file.contents = file.contents.slice 56
      console.log "file.contents" + file.contents
      # write PCHK header
      file.contents.writeUInt32LE 1, 0
      nksf:
        pchk: file
        nisi: "src/#{$.dir}/presets/#{file.relative[..-4]}meta"
    .pipe builder.gulp()
    .pipe rename extname: '.nksf'
    .pipe gulp.dest "dist/#{$.dir}/User Content/#{$.dir}"

# export
# --------------------------------

# export from .nksf to .adg ableton rack
gulp.task "#{$.prefix}-export-adg", ["#{$.prefix}-dist-presets"], ->
  exporter = adgExporter $.abletonRackTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpTemplate()
    .pipe gzip append: off       # append '.gz' extension
    .pipe rename extname: '.adg'
    .pipe gulp.dest "#{$.Ableton.racks}/#{$.dir}"

# generate ableton default plugin parameter configuration
gulp.task "#{$.prefix}-generate-appc", ->
  gulp.src "src/#{$.dir}/mappings/default.json"
    .pipe appcGenerator.gulpNica2Appc $.magic, $.dir
    .pipe rename
      basename: 'Default'
      extname: '.appc'
    .pipe gulp.dest "#{$.Ableton.defaults}/#{$.dir}"

# export from .nksf to .bwpreset bitwig studio preset
gulp.task "#{$.prefix}-export-bwpreset", ["#{$.prefix}-dist-presets"], ->
  exporter = bwExporter $.bwpresetTemplate
  gulp.src ["dist/#{$.dir}/User Content/#{$.dir}/**/*.nksf"]
    .pipe exporter.gulpParseNksf()
    .pipe exporter.gulpReadTemplate()
    .pipe exporter.gulpAppendPluginState()
    .pipe exporter.gulpRewriteMetadata()
    .pipe rename extname: '.bwpreset'
    .pipe gulp.dest "#{$.Bitwig.presets}/#{$.dir}"
