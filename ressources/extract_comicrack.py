"""Extract ComicRack zip, fixing Windows backslash paths."""
import zipfile

with zipfile.ZipFile("/tmp/comicrack.zip") as z:
    for info in z.infolist():
        # Le zip est créé sur Windows : les chemins utilisent des backslash.
        # On les convertit en slash pour créer la bonne arborescence Linux.
        info.filename = info.filename.replace("\\", "/")
        z.extract(info, "/opt/comicrack")
