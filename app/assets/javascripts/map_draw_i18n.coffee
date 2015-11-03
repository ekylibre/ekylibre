((E, $) ->
  "use strict"

  available_lang = ['fr', 'en']
  locales = { en:
    draw: {
      toolbar: {
        actions: {
          title: 'Cancel drawing',
          text: 'Cancel'
        },
        undo: {
          title: 'Delete last point drawn',
          text: 'Delete last point'
        },
        buttons: {
          polyline: 'Draw a polyline',
          polygon: 'Draw a polygon',
          rectangle: 'Draw a rectangle',
          circle: 'Draw a circle',
          marker: 'Draw a marker'
        }
      },
      handlers: {
        circle: {
          tooltip: {
            start: 'Click and drag to draw circle.'
          }
        },
        marker: {
          tooltip: {
            start: 'Click map to place marker.'
          }
        },
        polygon: {
          tooltip: {
            start: 'Click to start drawing shape.',
            cont: 'Click to continue drawing shape.',
            end: 'Click first point to close this shape.'
          }
        },
        polyline: {
          error: '<strong>Error:</strong> shape edges cannot cross!',
          tooltip: {
            start: 'Click to start drawing line.',
            cont: 'Click to continue drawing line.',
            end: 'Click last point to finish line.'
          }
        },
        rectangle: {
          tooltip: {
            start: 'Click and drag to draw rectangle.'
          }
        },
        simpleshape: {
          tooltip: {
            end: 'Release mouse to finish drawing.'
          }
        }
      }
    },
    edit: {
      toolbar: {
        actions: {
          save: {
            title: 'Save changes.',
            text: 'Save'
          },
          cancel: {
            title: 'Cancel editing, discards all changes.',
            text: 'Cancel'
          }
        },
        buttons: {
          edit: 'Edit layers.',
          editDisabled: 'No layers to edit.',
          remove: 'Delete layers.',
          removeDisabled: 'No layers to delete.'
        }
      },
      handlers: {
        edit: {
          tooltip: {
            text: 'Drag handles, or marker to edit feature.',
            subtext: 'Click cancel to undo changes.'
          }
        },
        remove: {
          tooltip: {
            text: 'Click on a feature to remove'
          }
        }
      }
    },
  fr:
    draw: {
      toolbar: {
        actions: {
          title: 'Annulez le dessin',
          text: 'Annuler'
        },
        undo: {
          title: 'Supprimer le dernier point déssiné',
          text: 'Supprimer le dernier point'
        },
        buttons: {
          polyline: 'Dessiner une polyligne',
          polygon: 'Dessiner un polygone',
          rectangle: 'Dessiner un rectangle',
          circle: 'Dessiner un cercle',
          marker: 'Dessiner un marqueur'
        }
      },
      handlers: {
        circle: {
          tooltip: {
            start: 'Cliquez et déplacez pour dessiner un cercle.'
          }
        },
        marker: {
          tooltip: {
            start: 'Cliquez sur la carte pour placer un marqueur.'
          }
        },
        polygon: {
          tooltip: {
            start: 'Cliquez pour commencer à dessiner une forme.',
            cont: 'Cliquez pour continuer à dessiner une forme.',
            end: 'Cliquez sur le dernier point pour fermer cette forme.'
          }
        },
        polyline: {
          error: '<strong>Erreur:</strong> Les arrêtes de la forme ne doivent pas se croiser!',
          tooltip: {
            start: 'Cliquez pour commencer à dessiner d\'une ligne.',
            cont: 'Cliquez pour continuer à dessiner une ligne.',
            end: 'Cliquez sur le dernier point pour terminer la ligne.'
          }
        },
        rectangle: {
          tooltip: {
            start: 'Cliquez et déplacez pour dessiner un rectangle.'
          }
        },
        simpleshape: {
          tooltip: {
            end: 'Relachez la souris pour finir de dessiner.'
          }
        }
      }
    },
    edit: {
      toolbar: {
        actions: {
          save: {
            title: 'Sauvegardez les changements.',
            text: 'Sauver'
          },
          cancel: {
            title: 'Annulez l\'édition, ignorer tous les changements.',
            text: 'Annuler'
          }
        },
        buttons: {
          edit: 'Editer les couches.',
          editDisabled: 'Pas de couches à éditer.',
          remove: 'Supprimer les couches.',
          removeDisabled: 'Pas de couches à supprimer.'
        }
      },
      handlers: {
        edit: {
          tooltip: {
            text: 'Déplacez les ancres, ou le marqueur pour éditer l\'objet.',
            subtext: 'Cliquez sur Annuler pour revenir sur les changements.'
          }
        },
        remove: {
          tooltip: {
            text: 'Cliquez sur l\'objet à enlever'
          }
        }
      }
    }
  }

  if available_lang.indexOf($('html').attr('lang')) != -1

    L.drawLocal = locales[$('html').attr('lang')]

) ekylibre, jQuery