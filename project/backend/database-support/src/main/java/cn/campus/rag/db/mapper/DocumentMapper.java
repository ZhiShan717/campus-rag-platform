package cn.campus.rag.db.mapper;

import cn.campus.rag.db.entity.Document;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface DocumentMapper extends BaseMapper<Document> {
    @Select("""
        SELECT c.id AS chunkId, c.document_id AS documentId, d.title AS documentTitle,
               d.version, c.chunk_no AS chunkNo, c.section_path AS sectionPath,
               c.content, d.source_type AS sourceType, d.source_note AS sourceNote
        FROM documents d JOIN chunks c ON c.document_id = d.id
        WHERE d.status = 'ACTIVE' AND d.effective_from <= #{asOf}
          AND (d.effective_to IS NULL OR #{asOf} < d.effective_to)
        ORDER BY d.id, c.chunk_no, c.id
        """)
    List<Map<String, Object>> selectEffectiveCandidates(@Param("asOf") LocalDate asOf);

    // The service must keep this lock and every revision write in one transaction.
    @Select("SELECT * FROM documents WHERE document_key = #{documentKey} ORDER BY id FOR UPDATE")
    List<Document> lockVersionFamily(@Param("documentKey") String documentKey);
}
