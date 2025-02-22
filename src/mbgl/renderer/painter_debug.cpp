#include <mbgl/renderer/painter.hpp>
#include <mbgl/renderer/debug_bucket.hpp>
#include <mbgl/tile/tile.hpp>
#include <mbgl/tile/tile_data.hpp>
#include <mbgl/map/map_data.hpp>
#include <mbgl/shader/plain_shader.hpp>
#include <mbgl/util/string.hpp>
#include <mbgl/gl/debugging.hpp>

using namespace mbgl;

void Painter::renderTileDebug(const Tile& tile) {
    MBGL_DEBUG_GROUP(std::string { "debug " } + std::string(tile.id));
    assert(tile.data);
    if (data.getDebug() != MapDebugOptions::NoDebug) {
        setClipping(tile.clip);
        if (data.getDebug() & (MapDebugOptions::Timestamps | MapDebugOptions::ParseStatus)) {
            renderDebugText(*tile.data, tile.matrix);
        }
        if (data.getDebug() & MapDebugOptions::TileBorders) {
            renderDebugFrame(tile.matrix);
        }
    }
}

void Painter::renderDebugText(TileData& tileData, const mat4 &matrix) {
    MBGL_DEBUG_GROUP("debug text");

    config.depthTest = GL_FALSE;

    if (!tileData.debugBucket || tileData.debugBucket->state != tileData.getState()
                              || !(tileData.debugBucket->modified == tileData.modified)
                              || !(tileData.debugBucket->expires == tileData.expires)
                              || tileData.debugBucket->debugMode != data.getDebug()) {
        tileData.debugBucket = std::make_unique<DebugBucket>(tileData.id, tileData.getState(), tileData.modified, tileData.expires, data.getDebug());
    }

    config.program = plainShader->getID();
    plainShader->u_matrix = matrix;

    // Draw white outline
    plainShader->u_color = {{ 1.0f, 1.0f, 1.0f, 1.0f }};
    config.lineWidth = 4.0f * data.pixelRatio;
    tileData.debugBucket->drawLines(*plainShader, glObjectStore);

#ifndef GL_ES_VERSION_2_0
    // Draw line "end caps"
    MBGL_CHECK_ERROR(glPointSize(2));
    tileData.debugBucket->drawPoints(*plainShader, glObjectStore);
#endif

    // Draw black text.
    plainShader->u_color = {{ 0.0f, 0.0f, 0.0f, 1.0f }};
    config.lineWidth = 2.0f * data.pixelRatio;
    tileData.debugBucket->drawLines(*plainShader, glObjectStore);

    config.depthFunc.reset();
    config.depthTest = GL_TRUE;
}

void Painter::renderDebugFrame(const mat4 &matrix) {
    MBGL_DEBUG_GROUP("debug frame");

    // Disable depth test and don't count this towards the depth buffer,
    // but *don't* disable stencil test, as we want to clip the red tile border
    // to the tile viewport.
    config.depthTest = GL_FALSE;
    config.stencilOp.reset();
    config.stencilTest = GL_TRUE;

    config.program = plainShader->getID();
    plainShader->u_matrix = matrix;

    // draw tile outline
    tileBorderArray.bind(*plainShader, tileBorderBuffer, BUFFER_OFFSET_0, glObjectStore);
    plainShader->u_color = {{ 1.0f, 0.0f, 0.0f, 1.0f }};
    config.lineWidth = 4.0f * data.pixelRatio;
    MBGL_CHECK_ERROR(glDrawArrays(GL_LINE_STRIP, 0, (GLsizei)tileBorderBuffer.index()));
}
