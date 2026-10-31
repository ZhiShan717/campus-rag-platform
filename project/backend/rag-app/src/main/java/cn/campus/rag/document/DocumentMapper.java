package cn.campus.rag.document;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 一个空接口，一个方法都不写。
 * 继承 BaseMapper<Document> 之后，MyBatis-Plus 在启动时自动给你生成
 * selectById / selectList / insert / updateById / deleteById ... 这些 SQL。
 */
@Mapper
public interface DocumentMapper extends BaseMapper<Document> {
}
